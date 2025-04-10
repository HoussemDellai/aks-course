# Network Isolated AKS cluster

# Defining environment variables

$RESOURCE_GROUP = "rg-aks-cluster-network-isolated"
$AKS_NAME = "aks-cluster"
$LOCATION = "swedencentral"
$VNET_NAME = "vnet-spoke"
$AKS_SUBNET_NAME = "snet-aks"
$ACR_SUBNET_NAME = "snet-acr"
$REGISTRY_NAME = "acr4aks19"
$CLUSTER_IDENTITY_NAME = "identity-aks-control-plane"
$KUBELET_IDENTITY_NAME = "identity-aks-kubelet"

# Create the virtual network and subnets

az group create --name $RESOURCE_GROUP --location $LOCATION
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --address-prefixes 192.168.0.0/16
az network vnet subnet create --name $AKS_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefixes 192.168.1.0/24
$SUBNET_ID = az network vnet subnet show --name $AKS_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --query 'id' --output tsv
az network vnet subnet create --name $ACR_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --address-prefixes 192.168.2.0/24 --private-endpoint-network-policies Disabled

# Disable virtual network outbound connectivity

az network vnet subnet update --name $AKS_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --default-outbound-access false

# Create the ACR and enable artifact cache

az acr create --resource-group $RESOURCE_GROUP --name $REGISTRY_NAME --sku Premium --public-network-enabled false
$REGISTRY_ID = az acr show --name $REGISTRY_NAME -g $RESOURCE_GROUP --query 'id' --output tsv
az acr cache create -n aks-managed-mcr -r $REGISTRY_NAME -g $RESOURCE_GROUP --source-repo "mcr.microsoft.com/*" --target-repo "aks-managed-repository/*"

# Create a private endpoint for the ACR

az network private-endpoint create --name pe-acr --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --subnet $ACR_SUBNET_NAME --private-connection-resource-id $REGISTRY_ID --group-id registry --connection-name connection-acr
$NETWORK_INTERFACE_ID = az network private-endpoint show --name pe-acr --resource-group $RESOURCE_GROUP --query 'networkInterfaces[0].id' --output tsv
$REGISTRY_PRIVATE_IP = az network nic show --ids $NETWORK_INTERFACE_ID --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry'].privateIPAddress" --output tsv
$DATA_ENDPOINT_PRIVATE_IP = az network nic show --ids $NETWORK_INTERFACE_ID --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry_data_$LOCATION'].privateIPAddress" --output tsv

# Create a private DNS zone and add records

az network private-dns zone create --resource-group $RESOURCE_GROUP --name "privatelink.azurecr.io"
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --zone-name "privatelink.azurecr.io" --name MyDNSLink --virtual-network $VNET_NAME --registration-enabled false
az network private-dns record-set a create --name $REGISTRY_NAME --zone-name "privatelink.azurecr.io" --resource-group $RESOURCE_GROUP
az network private-dns record-set a add-record --record-set-name $REGISTRY_NAME --zone-name "privatelink.azurecr.io" --resource-group $RESOURCE_GROUP --ipv4-address $REGISTRY_PRIVATE_IP
az network private-dns record-set a create --name "$REGISTRY_NAME.$LOCATION.data" --zone-name "privatelink.azurecr.io" --resource-group $RESOURCE_GROUP
az network private-dns record-set a add-record --record-set-name "$REGISTRY_NAME.$LOCATION.data" --zone-name "privatelink.azurecr.io" --resource-group $RESOURCE_GROUP --ipv4-address $DATA_ENDPOINT_PRIVATE_IP

# Create control plane and kubelet identities

az identity create --name $CLUSTER_IDENTITY_NAME --resource-group $RESOURCE_GROUP
$CLUSTER_IDENTITY_RESOURCE_ID = az identity show --name $CLUSTER_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'id' -o tsv
# $CLUSTER_IDENTITY_PRINCIPAL_ID = az identity show --name $CLUSTER_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'principalId' -o tsv
az identity create --name $KUBELET_IDENTITY_NAME --resource-group $RESOURCE_GROUP
$KUBELET_IDENTITY_RESOURCE_ID = az identity show --name $KUBELET_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'id' -o tsv
$KUBELET_IDENTITY_PRINCIPAL_ID = az identity show --name $KUBELET_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'principalId' -o tsv

# Grant AcrPull permissions for the Kubelet identity

az role assignment create --role AcrPull --scope $REGISTRY_ID --assignee-object-id $KUBELET_IDENTITY_PRINCIPAL_ID --assignee-principal-type ServicePrincipal

# Create network isolated cluster using the BYO ACR

az aks create --resource-group $RESOURCE_GROUP --name $AKS_NAME --kubernetes-version 1.30.3 --vnet-subnet-id $SUBNET_ID --assign-identity $CLUSTER_IDENTITY_RESOURCE_ID --assign-kubelet-identity $KUBELET_IDENTITY_RESOURCE_ID --bootstrap-artifact-source Cache --bootstrap-container-registry-resource-id $REGISTRY_ID --outbound-type none --network-plugin azure --enable-private-cluster

# Connect to the cluster

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing