# resource "azurerm_kubernetes_cluster" "aks" {
#   name                    = "aks-cluster"
#   resource_group_name     = azurerm_resource_group.rg.name
#   location                = azurerm_resource_group.rg.location
#   kubernetes_version      = "1.30.4"
#   dns_prefix              = "aks"
#   private_cluster_enabled = false

#   network_profile {
#     network_plugin      = "azure"
#     network_plugin_mode = "overlay"
#   }

#   default_node_pool {
#     name           = "systempool"
#     vm_size        = "Standard_D2s_v2"
#     node_count     = 3
#     zones          = [2, 3] # [1, 2, 3]
#     vnet_subnet_id = azurerm_subnet.snet-aks.id
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   #   kubelet_identity {
#   #     client_id                 = azurerm_user_assigned_identity.identity-kubelet.client_id
#   #     object_id                 = azurerm_user_assigned_identity.identity-kubelet.principal_id # there is no object_id
#   #     user_assigned_identity_id = azurerm_user_assigned_identity.identity-kubelet.id
#   #   }

#   lifecycle {
#     ignore_changes = [
#       default_node_pool[0].upgrade_settings
#     ]
#   }
# }

# resource "terraform_data" "aks-get-crdentials" {
#   triggers_replace = [
#     azurerm_kubernetes_cluster.aks.id
#   ]

#   provisioner "local-exec" {
#     command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
#   }
# }
