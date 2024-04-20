resource "terraform_data" "import-grafana-dashboard" {
  provisioner "local-exec" {
    command = "az grafana dashboard import -n ${azurerm_dashboard_grafana.grafana.name} --definition https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json"
  }

  triggers_replace = [ azurerm_dashboard_grafana.grafana.id ]
}

resource "terraform_data" "import-grafana-dashboard2" {
  provisioner "local-exec" {
    command = "az grafana dashboard import -n ${azurerm_dashboard_grafana.grafana.name} --definition https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/request-handling-performance.json"
  }

  triggers_replace = [ azurerm_dashboard_grafana.grafana.id ]
}