$AKS_NAME = "aks-cluster"
$AKS_RG = "rg-aks-cluster-egress-gw"
$NODEPOOL_NAME = "npegress"
$IDENTITY_NAME = "identity-egress-gateway"

az group create --name $AKS_RG --location westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure -k "1.28.3" # --zones 1 2 3 --node-vm-size "Standard_B2als_v2"

az aks nodepool add -g $AKS_RG --cluster-name $AKS_NAME --name $NODEPOOL_NAME

az aks get-credentials -g $AKS_RG -n $AKS_NAME --overwrite-existing

kubectl taint nodes -l agentpool=$NODEPOOL_NAME kubeegressgateway.azure.com/mode=true:NoSchedule

kubectl label nodes -l agentpool=$NODEPOOL_NAME kubeegressgateway.azure.com/mode=true

az aks nodepool update -g $AKS_RG --cluster-name $AKS_NAME --name $NODEPOOL_NAME --disable-cluster-autoscaler

# Use UserAssigned Managed Identity

# Create a UserAssigned managed identity. This identity can be created in any resource group as long as permissions are set correctly.

az identity create -g $AKS_RG -n $IDENTITY_NAME

# Retrieve the identityID and clientID from the identity you just created

$IDENTITY_CLIENT_ID = $(az identity show -g $AKS_RG -n $IDENTITY_NAME -o tsv --query "clientId")
echo $IDENTITY_CLIENT_ID

$IDENTITY_ID = $(az identity show -g $AKS_RG -n $IDENTITY_NAME -o tsv --query "id")
echo $IDENTITY_ID

# Assign "Network Contributor" and "Virtual Machine Contributor" roles to the identity. kube-egress-gateway components need these two roles to configure Load Balancer, Public IP Prefix, and VMSS resources.

$AKS_NODE_RG = $(az aks show -g $AKS_RG -n $AKS_NAME --query "nodeResourceGroup" -o tsv)
echo $AKS_NODE_RG

$AKS_NODE_RG_ID = $(az group show -g $AKS_NODE_RG --query id -o tsv)
echo $AKS_NODE_RG_ID
# get VMSS ID of the nodepool with name contains "npegress"

$VMSS_ID = $(az vmss list -g $AKS_NODE_RG --query [1].id -o tsv)
echo $VMSS_ID

$VMSS_NAME = $(az vmss list -g $AKS_NODE_RG --query [1].name -o tsv)
echo $VMSS_NAME

# assign Network Contributor role on scope networkResourceGroup and vmssResourceGroup to the identity
az role assignment create --role "Network Contributor" --assignee $IDENTITY_CLIENT_ID --scope $AKS_NODE_RG_ID
# az role assignment create --role "Network Contributor" --assignee $IDENTITY_CLIENT_ID --scope $vmssRGID

# assign Virtual Machine Contributor role on scope gateway vmss to the identity
az role assignment create --role "Virtual Machine Contributor" --assignee $IDENTITY_CLIENT_ID --scope $VMSS_ID

@"
config:
  azureCloudConfig:
    cloud: "AzurePublicCloud"
    tenantId: "$(az account show --query tenantId -o tsv)"
    subscriptionId: "$(az account show --query id -o tsv)"
    useManagedIdentityExtension: true
    userAssignedIdentityID: "$IDENTITY_ID"
    userAgent: "kube-egress-gateway-controller"
    resourceGroup: "$AKS_RG"
    location: "westeurope"
    gatewayLoadBalancerName: "kubeegressgateway-ilb"
    loadBalancerResourceGroup: "$AKS_NODE_RG"
    vnetName: "$(az network vnet list -g $AKS_NODE_RG --query [0].name -o tsv)"
    vnetResourceGroup: "$AKS_NODE_RG"
    subnetName: "aks-subnet"
"@ > azure_config_msi.yaml

# Install kube-egress-gateway as Helm Chart

git clone https://github.com/Azure/kube-egress-gateway.git

# To install kube-egress-gateway, you may run below helm command:

helm upgrade --install `
  kube-egress-gateway ./kube-egress-gateway/helm/kube-egress-gateway `
  --namespace kube-egress-gateway-system `
  --create-namespace `
  --set common.imageRepository=mcr.microsoft.com/aks `
  --set common.imageTag=v0.0.5 `
  -f azure_config_msi.yaml

# create public IP prefix

az network public-ip prefix create -g $AKS_RG -n myPIPPrefix --length 31
$IP_PREFIX_ID=$(az network public-ip prefix create -g $AKS_RG -n myPIPPrefix --length 31 --query id -o tsv)
echo $IP_PREFIX_ID

@"
apiVersion: egressgateway.kubernetes.azure.com/v1alpha1
kind: StaticGatewayConfiguration
metadata:
  name: my-static-egress-gateway
  namespace: default
spec:
  gatewayVmssProfile:
    vmssResourceGroup: $AKS_NODE_RG
    vmssName: $VMSS_NAME
    publicIpPrefixSize: 31
  provisionPublicIps: true
  publicIpPrefixId: $IP_PREFIX_ID
  defaultRoute: staticEgressGateway
  excludeCidrs:
    - 10.244.0.0/16
    - 10.245.0.0/16
"@ > static_gateway_config.yaml

kubectl apply -f static_gateway_config.yaml

kubectl get staticgatewayconfigurations my-static-egress-gateway -n default -o yaml