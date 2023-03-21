# Using Azure Disk in AKS

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-az"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

## 1. Deploy a sample deployment with PVC (Azure Disk with LRS)

kubectl apply -f lrs-disk-deploy.yaml

# Verify resources deployed successfully

kubectl get pods,pv,pvc

# Check the worker node for the pod

kubectl get pods -o wide

kubectl get nodes

# Worker Nodes are deployed into the 3 Azure Availability Zones

Set-Alias -Name grep -Value select-string # if using powershell

kubectl describe nodes | grep topology.kubernetes.io/zone

# Check the Availability Zone for our pod

# Get Pod's node name
$NODE_NAME=$(kubectl get pods -l app=nginx-lrs -o jsonpath='{.items[0].spec.nodeName}')
echo $NODE_NAME

kubectl get nodes $NODE_NAME -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'

kubectl describe nodes $NODE_NAME | grep topology.kubernetes.io/zone

## 2. Simulate node failure (delete node)

kubectl delete node $NODE_NAME

# Check the pod, we have a problem!

kubectl get pods -o wide

# Check Pod events

kubectl describe pod | grep Warning
# Warning  FailedScheduling  20s (x6 over 5m47s)  default-scheduler  0/3 nodes are available: 1 node(s) were unschedulable, 2 node(s) had volume node affinity conflict.

# The problem here is that the PV (Azure Disk) is zonal (uses 1 single availability zone (AZ)). 
# It could be detached from the VM and mounted into another VM. But that VM must be within the same AZ.
# If it is not within then same AZ, it will fail. And the pod will not be able to mount the disk.

## 3. Resolving the issue (adding nodes in the same AZ)

# What if we did have another VM inside the same Availability Zone ?

# Adding nodes to the availability zones

az aks scale -n $AKS_NAME -g $AKS_RG --node-count 6

# Check the created Nodes (note the missing node we deleted earlier!)

kubectl get nodes

# Verify we have nodes in all 3 availability zones (including AZ-2 where we have the Disk/PV)

kubectl describe nodes | grep topology.kubernetes.io/zone

# Check pod is now rescheduled into a node within AZ-2

kubectl get pods -o wide

# Verify the node is in availability zone 2

$NODE_NAME=$(kubectl get pods -l app=nginx-lrs -o jsonpath='{.items[0].spec.nodeName}')
$NODE_NAME

kubectl get nodes $NODE_NAME -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'

## Conclusion

# An Azure Disk of type LRS (Local Redundant Storage) is 'zonal resource'.
# This means it is available only within the same availability where it is created.
# LRS Disk cannot be moved to another AZ.
# This is not suitable for pods using multiple AZ.
#  The solution would be :
# + Choose another storage option that supports multiple AZ like Azure Files or Storage Blob.
# + Use Azure Disk with ZRS (Zone Redundant Storage), instead of LRS.
# We'll explore this last option in the next lab.