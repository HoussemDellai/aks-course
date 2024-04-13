resource "azurerm_kubernetes_fleet_manager" "fleet" {
  name                = "fleet-manager"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_kubernetes_fleet_member" "member" {
  for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.key].id
  kubernetes_fleet_id   = azurerm_kubernetes_fleet_manager.fleet.id
  name                  = "${each.key}-member"
}

resource "azurerm_kubernetes_cluster" "aks" {
  for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = each.value.version # "1.29.0"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    ebpf_data_plane     = "cilium"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name       = "systemnp"
    node_count = 2
    vm_size    = "Standard_B2als_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
  for_each = { for cluster in var.aks : cluster.cluster_name => cluster }

  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.key].id
  vm_size               = "Standard_B2als_v2"
  node_count            = each.value.node_count
  priority              = "Spot"
}

# resource "azurerm_kubernetes_fleet_update_run" "update_run" {
#   name                        = "update-run"
#   kubernetes_fleet_manager_id = azurerm_kubernetes_fleet_manager.fleet.id
#   managed_cluster_update {
#     upgrade {
#       type               = "Full"
#       kubernetes_version = "1.29.2"
#     }
#     node_image_selection {
#       type = "Latest"
#     }
#   }
#   stage {
#     name = "stage1"
#     group {
#       name = "group1"
#     }
#     after_stage_wait_in_seconds = 21
#   }
# }

# resource "azurerm_kubernetes_fleet_update_strategy" "update_strategy" {
#   name                        = "update-strategy"
#   kubernetes_fleet_manager_id = azurerm_kubernetes_fleet_manager.fleet.id
#   stage {
#     name = "stage-1"
#     group {
#       name = "group-1"
#     }
#     after_stage_wait_in_seconds = 21
#   }
# }

output "fleet_manager_hub_profile" {
  value = azurerm_kubernetes_fleet_manager.fleet.hub_profile
}
