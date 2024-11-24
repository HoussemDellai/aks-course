resource "azapi_update_resource" "enable-aks-static-egress-gateway" {
  type        = "Microsoft.ContainerService/ManagedClusters@2024-09-02-preview"
  resource_id = azurerm_kubernetes_cluster.aks.id

  body = {
    properties = {
      networkProfile = {
        staticEgressGatewayProfile = {
          enabled = true
        }
      }
    }
  }
}

# resource "terraform_data" "enable-aks-static-egress-gateway" {
#   triggers_replace = [azurerm_kubernetes_cluster.aks.id]

#   provisioner "local-exec" {
#     command = "az aks update -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --enable-static-egress-gateway"
#   }
# }

# az aks nodepool add -g $AKS_RG --cluster-name $AKS_NAME --name $NODEPOOL_NAME --mode gateway --node-count 2 --gateway-prefix-size $GW_PREFIX_SIZE --node-vm-size standard_d2pds_v6

# resource "terraform_data" "add-static-egress-gateway-nodepool" {
#   triggers_replace = [
#     azurerm_kubernetes_cluster.aks.id
#   ]

#   provisioner "local-exec" {
#     command = "az aks nodepool add --cluster-name ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --name npegresspr --mode gateway --node-count 2 --gateway-prefix-size 30 --node-vm-size standard_d2pds_v6"
#   }

#   depends_on = [
#     terraform_data.enable-aks-static-egress-gateway
#   ]
# }
