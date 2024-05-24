$aks="aks-cluster-automatic"
$rg="rg-aks-cluster-automatic"

# create a resource group

az group create -n $rg --location eastus

# create a cluster with Managed Prometheus and Container Insights integration enabled.

az aks create -n $aks -g $rg --sku automatic

# connect to the cluster

az aks get-credentials -n $aks -g $rg

# get nodes

kubectl get nodes

# create a namespace

kubectl create ns aks-store-demo

# deploy an app

kubectl apply -n aks-store-demo -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-ingress-quickstart.yaml

# test the app

kubectl get pods -n aks-store-demo

kubectl get ingress store-front -n aks-store-demo --watch



# resources

# https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-automatic-deploy?pivots=azure-cli