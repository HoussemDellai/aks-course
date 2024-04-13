# FinOps with Kubernetes, exploring Opencost

## Introduction

```sh
$RG="rg-aks-swc-85"

az group create -n $RG -l swedencentral

$log_analytics_id=$(az monitor log-analytics workspace create -g $RG --workspace-name log-analytics --query id -o tsv)

$prometheus_id=$(az monitor account create -n azure-prometheus -g $RG --query id -o tsv)

$grafana_id=$(az grafana create -n azure-grafana-15 -g $RG --query id -o tsv)

az aks create -n aks-cluster -g $RG --network-plugin azure --network-plugin-mode overlay -k 1.29.0 --enable-azure-monitor-metrics --enable-addons monitoring --azure-monitor-workspace-resource-id $prometheus_id --grafana-resource-id $grafana_id --workspace-resource-id $log_analytics_id

az aks get-credentials -n aks-cluster -g $RG --overwrite-existing


helm repo update

helm install prometheus --repo https://prometheus-community.github.io/helm-charts prometheus \
  --namespace prometheus-system --create-namespace \
  --set prometheus-pushgateway.enabled=false \
  --set alertmanager.enabled=false \
  -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/prometheus/extraScrapeConfigs.yaml

kubectl create namespace opencost

az role definition create --verbose --role-definition RateCardQueryRole.json

$SUBSCRIPTION_ID=$(az account list --query [?isDefault].id -o tsv)
az ad sp create-for-rbac --name "OpenCostAccess" --role "OpenCostRole" --scope "/subscriptions/$SUBSCRIPTION_ID" --output json

kubectl create secret generic azure-service-key -n opencost --from-file=service-key.json

helm repo add opencost-charts https://opencost.github.io/opencost-helm-chart
helm repo update

helm install opencost opencost-charts/opencost --namespace opencost --create-namespace -f values.yaml

kubectl port-forward --namespace opencost service/opencost 9003 9090
```