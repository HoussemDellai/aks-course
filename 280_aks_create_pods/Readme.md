# Creating Pods using Kubernetes Python SDK

## Create an AKS cluster

```sh
az group create -n rg-aks-cluster -l swedencentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.32.0 --node-vm-size standard_d2ads_v5
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Explore the Python SDK for Kubernetes using Notebook

Open and run the steps in the `.ipynb` python notebook file.