# Using Azure Disk in AKS

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-zrs"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

## 1. Deploy a sample deployment with PVC (Azure Disk with zrs)

kubectl apply -f zrs-disk-deploy.yaml -f .\zrs-disk-storage-class.yaml

# Verify resources deployed successfully

kubectl get pods,pv,pvc

# Verify data persisted in the disk

$POD_NAME=$(kubectl get pods -l app=nginx-zrs -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME
kubectl exec $POD_NAME -it -- cat /mnt/azuredisk/outfile

# Check the worker node for the pod

kubectl get pods -o wide

kubectl get nodes

# Worker Nodes are deployed into the 3 Azure Availability Zones

Set-Alias -Name grep -Value select-string # if using powershell

kubectl describe nodes | grep topology.kubernetes.io/zone

# Check the Availability Zone for our pod

# Get Pod's node name
$NODE_NAME=$(kubectl get pods -l app=nginx-zrs -o jsonpath='{.items[0].spec.nodeName}')
echo $NODE_NAME

kubectl get nodes $NODE_NAME -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'

kubectl describe nodes $NODE_NAME | grep topology.kubernetes.io/zone

## 2. Simulate zone failure (delete or drain nodes in AZ)

kubectl drain $NODE_NAME --force --delete-emptydir-data --ignore-daemonsets

## 3. Verify the pod will be rescheduled in another zone

kubectl get pods -o wide -w

# Thanks to using ZRS Disk, our pod will be resheduled to another availability zone.

# Check the availability zone for that node

# Get Pod's new node name
$NODE_NAME=$(kubectl get pods -l app=nginx-zrs -o jsonpath='{.items[0].spec.nodeName}')
echo $NODE_NAME

kubectl describe nodes $NODE_NAME | grep topology.kubernetes.io/zone

## 4. Verify the data inside the Disk

$POD_NAME=$(kubectl get pods -l app=nginx-zrs -o jsonpath='{.items[0].metadata.name}')
 $ echo $POD_NAME
# nginx-zrs-566dfd89ff-7kltc

kubectl exec $POD_NAME -it -- cat /mnt/azuredisk/outfile
# Fri Dec 23 07:41:13 UTC 2022
# Fri Dec 23 07:41:14 UTC 2022
# Fri Dec 23 07:41:15 UTC 2022