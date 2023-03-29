# create an AKS cluster with Kubenet network plugin

az group create -n rg-aks-kubenet -l westeurope

az aks create -n aks-kubenet -g rg-aks-kubenet --network-plugin kubenet --no-wait

# create an AKS cluster with Azure CNI network plugin

az group create -n rg-aks-cni -l westeurope

az aks create -n aks-cni -g rg-aks-cni --network-plugin azure --no-wait

# create an AKS cluster with Azure CNI Overlay network plugin

az group create -n rg-aks-cni-overlay -l westeurope

az aks create -n aks-cni-overlay -g rg-aks-cni-overlay --network-plugin azure --network-plugin-mode overlay --pod-cidr 192.168.0.0/16 --no-wait

# connect to Kubenet AKS cluster

az aks get-credentials -n aks-kubenet -g rg-aks-kubenet

# get pods IP addresses only
kubectl get pods -o wide