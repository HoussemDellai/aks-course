# create an AKS cluster with Azure CNI network plugin

az group create -n rg-aks-cluster -l westeurope

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure

# AKS by default uses 10.224.0.0/12 for VNET and 10.224.0.0/16 for Subnet

# enable Azure Application Gateway Ingress Controller

az aks addon enable -n aks-cluster -g rg-aks-cluster `
       --addon ingress-appgw `
       --appgw-subnet-cidr 10.225.0.0/16 `
       --appgw-name gateway

# connect to AKS cluster

az aks get-credentials -n aks-cluster -g rg-aks-cluster

# view the ingress class created by AGIC

kubectl get ingressclass

# deploy a simple app with ingress

kubectl apply -f ingress_appgw.yaml

kubectl get pods,svc,ingress

kubectl get pods -o wide