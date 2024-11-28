# https://headlamp.dev/

az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.31.1 --node-vm-size standard_d2pds_v6

az aks get-credentials -n aks-cluster -g rg-aks-cluster

# install headlamp into AKS

helm repo add headlamp https://headlamp-k8s.github.io/headlamp/
helm install my-headlamp headlamp/headlamp --namespace kube-system

# install headlamp into local machine
# It can be run as a web app, desktop app, or both.

winget install headlamp