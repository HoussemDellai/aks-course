# https://gateway.envoyproxy.io/docs/tasks/extensibility/ext-proc/

az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.32.4 --node-vm-size standard_d2ads_v5