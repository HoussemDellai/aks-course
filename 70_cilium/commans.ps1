
$AKS_NAME="aks-cluster"
$AKS_RG="rg-aks-cluster"

az group create -n $AKS_RG -l westeurope

az network vnet create -g $AKS_RG --location westeurope --name aks-vnet --address-prefixes "10.0.0.0/8"

az network vnet subnet create -g $AKS_RG --vnet-name aks-vnet --name nodesubnet --address-prefixes "10.240.0.0/16"

az network vnet subnet create -g $AKS_RG --vnet-name aks-vnet --name podsubnet --address-prefixes "10.241.0.0/16"

$NODESUBNET_ID=$(az network vnet subnet show -g $AKS_RG --vnet-name aks-vnet -n nodesubnet --query id)

$PODSUBNET_ID=$(az network vnet subnet show -g $AKS_RG --vnet-name aks-vnet -n podsubnet --query id)

az aks create -n $AKS_NAME -g $AKS_RG -l westeurope `
  --max-pods 250 `
  --network-plugin azure `
  --enable-cilium-dataplane `
  --vnet-subnet-id $NODESUBNET_ID `
  --pod-subnet-id $PODSUBNET_ID
