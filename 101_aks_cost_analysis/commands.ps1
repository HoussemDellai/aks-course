az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --tier standard --enable-cost-analysis --network-plugin azure --network-plugin-mode overlay -k 1.31.1 --node-vm-size standard_d2pds_v6

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing

# Enable Workload ID

