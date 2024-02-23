

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