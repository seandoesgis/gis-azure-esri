# Nginx Reverse Proxy Setup for ArcGIS Enterprise

Ubuntu VM (B1s) in public subnet (10.0.3.0/24)
Public IP: 20.246.90.140
DNS: arcgis2.dvrpc.org

## Install
```
sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx HTTPS'
sudo ufw allow 'OpenSSH'
sudo ufw enable
```

## Security Configuration

### Azure NSG Rules (nginx-nsg)
- Allow HTTP (80)
- Allow HTTPS (443)
- Allow SSH (22) from specific IP

### UFW Rules
```
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## SSL Configuration

### Create SSL directory
```
sudo mkdir -p /etc/nginx/ssl
```

### Extract certificate from PFX
```
sudo openssl pkcs12 -in wildcard2025.pfx -nocerts -legacy -out /etc/nginx/ssl/nginx.key -nodes
sudo openssl pkcs12 -in wildcard2025.pfx -clcerts -legacy -nokeys -out /etc/nginx/ssl/nginx.crt
```

### Set permissions
```
sudo chmod 600 /etc/nginx/ssl/nginx.key
sudo chmod 644 /etc/nginx/ssl/nginx.crt
```

## Nginx Configuration
File: /etc/nginx/sites-available/arcgis

```
server {
    listen 443 ssl;
    server_name arcgis2.dvrpc.org;

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Portal
    location /dvrpc/ {
        proxy_pass https://dvrpcgis-enterp/dvrpc/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
        proxy_set_header X-Forwarded-Host $host;
        proxy_redirect https://dvrpcgis-enterp/dvrpc/ https://arcgis2.dvrpc.org/dvrpc/;
        sub_filter_once off;
    }

    # Server
    location /portal/ {
        proxy_pass https://dvrpcgis-enterp/portal/;
        proxy_set_header Host dvrpcgis-enterp;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_ssl_verify off;
        proxy_redirect off;
        sub_filter_once off;
        sub_filter 'dvrpcgis-enterp' 'arcgis2.dvrpc.org';
    }
}

## HTTP to HTTPS redirect
server {
    listen 80;
    server_name arcgis2.dvrpc.org;
    return 301 https://$host$request_uri;
}
```

## Enable Configuration
```
sudo ln -s /etc/nginx/sites-available/arcgis /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## ArcGIS Configuration
Web context URL set to arcgis2.dvrpc.org in ArcGIS Server settings
Portal and Server accessible via:

- Portal: https://arcgis2.dvrpc.org/dvrpc/home
- Server: https://arcgis2.dvrpc.org/portal/rest

This setup provides a secure reverse proxy for ArcGIS Enterprise, handling both Portal and Server traffic through a single endpoint with SSL encryption.