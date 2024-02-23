



az grafana dashboard import `
           --name ${azurerm_dashboard_grafana.grafana.name} `
           --resource-group ${azurerm_dashboard_grafana.grafana.resource_group_name} `
           --definition \"https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json\"


az grafana dashboard import `
           --name ${azurerm_dashboard_grafana.grafana.name} `
           --resource-group ${azurerm_dashboard_grafana.grafana.resource_group_name} `
           --definition \"https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/request-handling-performance.json\"



helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --namespace ingress --create-namespace

kubectl apply -f deploy-svc-ingress.yaml


# Kubernetes / API server
az grafana dashboard import --name azure-grafana-aks --resource-group rg-monitoring --definition 20331

# Kubernetes / ETCD
az grafana dashboard import --name azure-grafana-aks --resource-group rg-monitoring --definition 20330