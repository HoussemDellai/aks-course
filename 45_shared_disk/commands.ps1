# https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/deploy/example/failover/README.md

# Using Azure Shared Disk in AKS

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-shared-disk"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 6 --zones 1 2 3 --kubernetes-version "1.25.2" --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

## 1. Deploy a sample deployment with StorageClass and PVC (ZRS Shared Azure Disk)

kubectl apply -f zrs-shared-disk-pvc-sc.yaml,zrs-shared-disk-deploy.yaml

# Verify resources deployed successfully

kubectl get pods,pv,pvc,sc

# Verify the pods are deployed in multiple nodes

kubectl get pods -o wide

# Verify the pods are deployed in multiple availability zones

Set-Alias -Name grep -Value select-string # if using powershell
kubectl describe nodes | grep topology.kubernetes.io/zone

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
echo $NODE_RG

az disk list -g $NODE_RG -o table

# Check the Disk config on the Azure portal

# Verify the Disk is accessible by 3 nodes

az disk list -g $NODE_RG --query [0].managedByExtended

# Verify access to Shared Disk on Pod #1

$POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME

kubectl exec -it $POD_NAME -- dd if=/dev/zero of=/dev/sdx bs=1024k count=100

# Verify access to Shared Disk on Pod #2

$POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[1].metadata.name}')
echo $POD_NAME

kubectl exec -it $POD_NAME -- dd if=/dev/zero of=/dev/sdx bs=1024k count=100