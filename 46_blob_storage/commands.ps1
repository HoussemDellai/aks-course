# Using Azure Blob Storage in AKS

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-storage-blob"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 --kubernetes-version "1.25.2" --network-plugin azure  --enable-blob-driver

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# Verify the blob driver (DaemonSet) was installed

Set-Alias -Name grep -Value select-string # if using powershell
kubectl get pods -n kube-system | grep csi

# When the Azure Blob storage CSI driver is enabled on AKS, there are two built-in storage classes: azureblob-fuse-premium and azureblob-nfs-premium.

kubectl get storageclass

kubectl get sc azureblob-fuse-premium -o yaml

kubectl get sc azureblob-nfs-premium -o yaml

## 1. Deploy a sample deployment with StorageClass and PVC

kubectl apply -f azure-blob-nfs-ss.yaml

kubectl get sts,pods,pvc,pv,secret

kubectl get secret -o yaml

# Check the created storage account in Azure portal

# View Storage Account configuration

# Check the network configuration and note how it added access to AKS VNET

# Check the storage account access keys

# View the created container blob, note the same name as the PVC

# View the content (the file we created inside the container) of the blob

# View the file content

# Get the created storage accounts using Azure CLI

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)

az storage account list -g $NODE_RG -o table

kubectl exec -it statefulset-blob-nfs-0 -- df -h

kubectl exec -it statefulset-blob-nfs-0 -- cat /mnt/azureblob/data

# Azure Blob CSI driver only supports NFS 3.0 protocol for Kubernetes versions 1.25 (preview) on AKS.
# kubectl apply -f azure-blobfuse-ss.yaml
# statefulset.apps/statefulset-blob created
