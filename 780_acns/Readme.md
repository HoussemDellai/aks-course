```sh
az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium -k 1.33.3 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration --enable-acns --acns-advanced-networkpolicies L7

# --enable-retina-flow-logs --acns-advanced-networkpolicies FQDN

# Create Azure monitor resource
az resource create --resource-group rg-aks-cluster --namespace microsoft.monitor --resource-type accounts --name azure-monitor-aks --location swedencentral --properties '{}'

# Create Grafana instance
az grafana create --name azure-grafana-780 --resource-group rg-aks-cluster

$grafanaId=$(az grafana show --name azure-grafana-780 --resource-group rg-aks-cluster --query id --output tsv)
$azuremonitorId=$(az resource show --resource-group rg-aks-cluster --name azure-monitor-aks --resource-type "Microsoft.Monitor/accounts" --query id --output tsv)

# Link to AKS
az aks update --name aks-cluster --resource-group rg-aks-cluster --enable-azure-monitor-metrics --azure-monitor-workspace-resource-id $azuremonitorId --grafana-resource-id $grafanaId

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```