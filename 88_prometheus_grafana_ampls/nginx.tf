# resource "helm_release" "ingress-nginx" {
#   name              = "ingress-nginx"
#   chart             = "third-party-helm/ingress-nginx"
#   namespace         = "ingress-nginx"
#   version           = "4.9.1" # "4.7.0"
#   create_namespace  = true
#   dependency_update = true

#   set {
#     name  = "controller.nodeSelector.kubernetes\\.io/os"
#     value = "linux"
#   }
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
#     value = "/healthz"
#   }
#   set {
#     name  = "metrics.enabled"
#     value = "true"
#   }
#   set {
#     name  = "controller.podAnnotations.prometheus\\.io/scrape"
#     value = "true"
#   }
#   #set {
#   #  name  = "controller.podAnnotations.prometheus\\.io/port"
#   #  value = "10254"
#   #}
# }

# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)

#     # username               = azurerm_kubernetes_cluster.aks.kube_admin_config.0.username
#     # password               = azurerm_kubernetes_cluster.aks.kube_admin_config.0.password
#     # client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
#     # client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
#   }
# #   registry {
# #     # Manually perform a `helm repo update` on the runner before running Terraform
# #     url      = "oci://artifacts.private.registry"
# #     username = "api"
# #     # Pass in secret on environment variable named TF_VAR_artifactAPIToken
# #     password = var.artifactAPIToken
# #   }
# }