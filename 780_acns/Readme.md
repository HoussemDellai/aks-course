```sh
az group create -n rg-aks-cluster-780 -l swedencentral

# Create Azure monitor resource
az resource create --resource-group rg-aks-cluster-780 --namespace microsoft.monitor --resource-type accounts --name azure-monitor-780 --location swedencentral --properties '{}'

# Create Grafana instance
az grafana create --name azure-grafana-780a --resource-group rg-aks-cluster-780

az monitor log-analytics workspace create -g rg-aks-cluster-780 --workspace-name log-analytics-780

$grafanaId=$(az grafana show --name azure-grafana-780a --resource-group rg-aks-cluster-780 --query id --output tsv)
$azuremonitorId=$(az resource show --resource-group rg-aks-cluster-780 --name azure-monitor-780 --resource-type "Microsoft.Monitor/accounts" --query id --output tsv)
$loganalyticsId=$(az monitor log-analytics workspace show --resource-group rg-aks-cluster-780 --workspace-name log-analytics-780 --query id --output tsv)

# # Link to AKS
# az aks update --name aks-cluster --resource-group rg-aks-cluster-780 --enable-azure-monitor-metrics --azure-monitor-workspace-resource-id $azuremonitorId --grafana-resource-id $grafanaId

az aks create -n aks-cluster -g rg-aks-cluster-780 --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium -k 1.33.3 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration --enable-azure-monitor-metrics --enable-addons monitoring --azure-monitor-workspace-resource-id $azuremonitorId --grafana-resource-id $grafanaId --workspace-resource-id $loganalyticsId --enable-acns --acns-advanced-networkpolicies L7 

# --enable-retina-flow-logs

az aks get-credentials -n aks-cluster -g rg-aks-cluster-780 --overwrite-existing


 az aks addon list -g rg-aks-cluster-780 --name aks-cluster
 az aks disable-addons -a monitoring -g rg-aks-cluster-780 -n aks-cluster
#  You complete this step because monitoring addons might already be enabled, but not for high scale. For more information, see High-scale mode.

 az aks enable-addons -a monitoring --enable-high-log-scale-mode -g rg-aks-cluster-780 -n aks-cluster --workspace-resource-id $loganalyticsId

 az aks update --enable-acns --enable-retina-flow-logs -g rg-aks-cluster-780 -n aks-cluster

