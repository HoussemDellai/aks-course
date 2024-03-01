# https://github.com/Azure/prometheus-collector/blob/main/AddonTerraformTemplate/main.tf

$grafana_name=(terraform output grafana_name)
$grafana_rg_name=(terraform output grafana_rg_name)

$aks_name=(terraform output aks_name)
$aks_rg_name=(terraform output aks_rg_name)

az grafana dashboard import `
           --name $grafana_name `
           --resource-group $grafana_rg_name `
           --definition "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json"


az grafana dashboard import `
           --name $grafana_name `
           --resource-group $grafana_rg_name `
           --definition "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/request-handling-performance.json"



az aks get-credentials --resource-group $aks_rg_name --name $aks_name --overwrite-existing

helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --namespace ingress --create-namespace

kubectl apply -f deploy-svc-ingress.yaml

kubectl apply -f container-azm-ms-agentconfig.yaml

kubectl apply -f ama-metrics-settings-configmap.yaml

# Kubernetes / API server
az grafana dashboard import --name $grafana_name --resource-group $grafana_rg_name --definition 20331

# Kubernetes / ETCD
az grafana dashboard import --name $grafana_name --resource-group $grafana_rg_name --definition 20330

# Dashboard for IP consumption
# https://github.com/Azure/azure-container-networking/tree/master/cns/doc/examples/metrics
kubectl -n kube-system get nnc
# NAME                                 ALLOCATED IPS   NC MODE   NC VERSION
# aks-systempool-96223890-vmss000000   256             static    0
# aks-systempool-96223890-vmss000001   256             static    0
# aks-systempool-96223890-vmss000002   256             static    0

# https://github.com/grafana/helm-charts/tree/main/charts/grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install grafana grafana/grafana --namespace monitoring --create-namespace --set persistence.enabled=true --set persistence.size=10Gi --set adminPassword=admin --set service.type=LoadBalancer