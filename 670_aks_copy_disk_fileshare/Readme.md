# Copying Disk and File Shares in AKS

## Creating an AKS cluster

```sh
az group create --name rg-aks-cluster --location francecentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.32.4 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Install 