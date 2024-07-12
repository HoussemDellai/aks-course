# AKS Cluster Autoscaler demystified

Disclaimer: This video is part of my Udemy course: https://www.udemy.com/course/learn-aks-network-security

```sh
az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.29.4 --enable-cluster-autoscaler --min-count 1 --max-count 10 --cluster-autoscaler-profile scan-interval=10s,scale-down-delay-after-add=0s,scale-down-unneeded-time=10s,scale-down-unready-time=10s,scale-down-utilization-threshold=0.5

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing

kubectl get nodes
```