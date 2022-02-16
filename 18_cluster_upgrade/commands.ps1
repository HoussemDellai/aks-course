# 1. setup demo environment
# variables
$AKS_NAME="aks-dev-07"
$AKS_RG="rg-aks-dev-07"

az aks get-versions -l westeurope -o table

$VERSION_OLD="1.21.7"
$VERSION_NEW="1.22.4"

# create and connect to cluster
az group create --name $AKS_RG `
                --location westeurope
az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 2 `
              --kubernetes-version $VERSION_OLD `
              --generate-ssh-keys

az aks get-credentials --name $AKS_NAME `
                       --resource-group $AKS_RG

kubectl get nodes

# (optional) add system nodepool with taints
az aks nodepool add --name systempool `
                    --cluster-name $AKS_NAME `
                    --resource-group $AKS_RG `
                    --node-count 2 `
                    --node-vm-size Standard_D2s_v5 `
                    --kubernetes-version $VERSION_OLD `
                    --max-pods 110 `
                    --priority Regular `
                    --zones 1, 2, 3 `
                    --node-taints CriticalAddonsOnly=true:NoSchedule `
                    --mode System

# (optional) remove old system nodepool
az aks nodepool delete --cluster-name $AKS_NAME `
                       --name nodepool1 `
                       --resource-group $AKS_RG `
                       --no-wait

# add user Nodepool blue
az aks nodepool add `
     --cluster-name $AKS_NAME `
     --resource-group $AKS_RG `
     --name bluepool `
     --node-count 3 `
     --node-vm-size Standard_D2s_v5 `
     --kubernetes-version $VERSION_OLD `
     --max-pods 110 `
     --priority Regular `
     --zones 1, 2, 3 `
     --mode User

az aks nodepool list --cluster-name $AKS_NAME `
                     --resource-group $AKS_RG `
                     -o table

# deploy stateless application
kubectl create deployment nginx --image=nginx --replicas=10 -o yaml --dry-run=client

kubectl create deployment nginx --image=nginx --replicas=10

# view pods running in blue nodepool
kubectl get pods -o wide -w

# 2. start the cluster upgrade
az aks list -o table

# upgrade control plane only
echo $VERSION_NEW

az aks upgrade --kubernetes-version $VERSION_NEW `
               --control-plane-only `
               --name $AKS_NAME `
               --resource-group $AKS_RG

# add user Nodepool green
echo $VERSION_NEW

az aks nodepool add `
     --cluster-name $AKS_NAME `
     --resource-group $AKS_RG `
     --name greenpool `
     --node-count 3 `
     --node-vm-size Standard_D2s_v5 `
     --kubernetes-version $VERSION_NEW `
     --max-pods 110 `
     --priority Regular `
     --zones 1, 2, 3 `
     --mode User

az aks nodepool list --cluster-name $AKS_NAME `
                     --resource-group $AKS_RG `
                     -o table

# cordon nodepool blue
kubectl cordon -l agentpool=bluepool

# drain nodepool blue
kubectl drain -l agentpool=bluepool --ignore-daemonsets --delete-local-data

# check nginx pods are rescheduled to green nodepool
kubectl get pods -o wide -w

# delete nodepool blue
az aks nodepool delete --name bluepool `
                       --cluster-name $AKS_NAME `
                       --resource-group $AKS_RG `
                       --no-wait