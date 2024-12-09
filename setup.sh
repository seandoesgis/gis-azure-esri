# Variables
RESOURCE_GROUP="gis"
LOCATION="eastus2"
VNET_NAME="arcgis-vnet"
SUBNET_NAME="arcgis-private-subnet"
DB_SUBNET_NAME="postgresql-subnet"
NSG_NAME="arcgis-nsg"
VNET_ADDRESS_PREFIX="10.0.0.0/16"
SUBNET_ADDRESS_PREFIX="10.0.1.0/24"
DB_SUBNET_PREFIX="10.0.2.0/24"
YOUR_IP="71.185.33.70/32"
PUBLIC_SUBNET_NAME="public-subnet"
PUBLIC_SUBNET_PREFIX="10.0.3.0/24"
PUBLIC_NSG_NAME="nginx-nsg"

# Create Virtual Network
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefix $VNET_ADDRESS_PREFIX \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix $SUBNET_ADDRESS_PREFIX \
    --location $LOCATION

# Create Network Security Group
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name $NSG_NAME \
    --location $LOCATION

# Add NSG rule for RDP from your IP
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name "Allow-RDP" \
    --priority 100 \
    --source-address-prefixes $YOUR_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 3389 \
    --access Allow \
    --protocol Tcp \
    --description "Allow RDP from specified IP"

# Add NSG rule for PostgreSQL
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name "Allow-PostgreSQL" \
    --priority 110 \
    --source-address-prefixes $YOUR_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 5432 \
    --access Allow \
    --protocol Tcp \
    --description "Allow PostgreSQL from specified IP"

# Associate NSG with subnet
az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --network-security-group $NSG_NAME

# Create PostgreSQL subnet with delegation
az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $DB_SUBNET_NAME \
    --address-prefix $DB_SUBNET_PREFIX \
    --delegations Microsoft.DBforPostgreSQL/flexibleServers

# Add NSG rule for PostgreSQL
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name "Allow-PostgreSQL" \
    --priority 110 \
    --source-address-prefixes $YOUR_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 5432 \
    --access Allow \
    --protocol Tcp \
    --description "Allow PostgreSQL from specified IP"

# Associate NSG with VM subnet
echo "Associating NSG with VM subnet..."
az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --network-security-group $NSG_NAME

# Create public subnet
az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $PUBLIC_SUBNET_NAME \
    --address-prefix $PUBLIC_SUBNET_PREFIX

# Create NSG for public subnet
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_NSG_NAME \
    --location $LOCATION

# Add NSG rules
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $PUBLIC_NSG_NAME \
    --name "Allow-HTTPS" \
    --priority 100 \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 443 \
    --access Allow \
    --protocol Tcp

az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $PUBLIC_NSG_NAME \
    --name "Allow-SSH" \
    --priority 110 \
    --source-address-prefixes $YOUR_IP \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp

# Associate NSG with public subnet
az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $PUBLIC_SUBNET_NAME \
    --network-security-group $PUBLIC_NSG_NAME

# Allow nginx to see portal and server ports in private subnet
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name "Allow-Portal-Server" \
    --priority 120 \
    --source-address-prefixes "$PUBLIC_SUBNET_PREFIX" \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 6443 7443 \
    --access Allow \
    --protocol Tcp \
    --description "Allow Nginx access to Portal and Server"