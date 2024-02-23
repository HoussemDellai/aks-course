# resource "terraform_data" "import-grafana-dashboard" {
# #   triggers_replace = [var.image_tag_aca_app_job]

#   provisioner "local-exec" {
#     when        = create
#     # interpreter = ["C:\\Program Files\\Git\\git-bash.exe", "-c"]
#     command     = "az grafana dashboard import --name ${azurerm_dashboard_grafana.grafana.name} --resource-group ${azurerm_dashboard_grafana.grafana.resource_group_name} --definition \"https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json\""
#   }
# }

# resource "terraform_data" "import-grafana-dashboard-nginx-2" {
#   provisioner "local-exec" {
#     when        = create
#     # command     = "az group list -o table"
#     command     = "az grafana dashboard import --name ${azurerm_dashboard_grafana.grafana.name} --resource-group ${azurerm_dashboard_grafana.grafana.resource_group_name} --definition \"https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/request-handling-performance.json\""
#   }
# }