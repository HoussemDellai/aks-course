# 1. Setup environment

$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.5" `
              --node-count 3 `
              --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# Add 2 user nodepools to the cluster

az aks nodepool add --name nodepool01 `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --node-count 3 `
       --zones 1 2 3 `
       --mode User

az aks nodepool add --name nodepool02 `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --node-count 3 `
       --zones 1 2 3 `
       --mode User

az aks nodepool list -g $AKS_RG --cluster-name $AKS_NAME -o table

# 2. Get labels for nodes

kubectl get nodes --show-labels
Set-Alias -Name grep -Value select-string # only on powershell
kubectl get nodes -o json | jq '.items[].metadata.labels' | grep agentpool

# 3. Create namespace with annotations

kubectl create namespace ns01

kubectl annotate namespace ns01 "scheduler.alpha.kubernetes.io/node-selector=agentpool=nodepool01"

kubectl describe namespace ns01

# 4. Deploy sample app

kubectl create deployment nginx01 --image=nginx --replicas=5 -n ns01

kubectl get pods -n ns01 -o wide

$POD_NAME=$(kubectl get pods -n ns01 -o jsonpath='{.items[0].metadata.name}')
$POD_NAME

kubectl describe pod $POD_NAME -n ns01

# 5. Create namespace with annotations

kubectl create namespace ns02

kubectl annotate namespace ns02 "scheduler.alpha.kubernetes.io/node-selector=agentpool=nodepool02"

kubectl describe namespace ns02

kubectl create deployment nginx01 --image=nginx --replicas=5 -n ns02

kubectl get pods -n ns02 -o wide