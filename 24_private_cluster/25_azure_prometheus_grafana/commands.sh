az group create -n rg-aks-cluster -l westeurope
az aks create -n aks-cluster -g rg-aks-cluster

# az aks update -n aks-cluster -g rg-aks-cluster --enable-managed-identity

# az aks enable-addons -n aks-cluster -g rg-aks-cluster -a monitoring --enable-msi-auth-for-monitoring 