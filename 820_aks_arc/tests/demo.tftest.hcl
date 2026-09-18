mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

run "three_overlay_cilium_clusters_with_arc" {
  command = plan

  assert {
    condition     = toset(keys(azurerm_kubernetes_cluster.cluster)) == toset(["dev", "ppr", "prd"])
    error_message = "The demo must contain exactly dev, ppr and prd."
  }

  assert {
    condition = alltrue([
      for cluster in azurerm_kubernetes_cluster.cluster :
      cluster.network_profile[0].network_plugin == "azure" &&
      cluster.network_profile[0].network_plugin_mode == "overlay" &&
      cluster.network_profile[0].network_data_plane == "cilium" &&
      cluster.network_profile[0].network_policy == "cilium"
    ])
    error_message = "Every cluster must use Azure CNI Overlay with Cilium networking and policy."
  }

  assert {
    condition = alltrue([
      for environment, arc in terraform_data.arc :
      arc.input.cluster_name == azurerm_kubernetes_cluster.cluster[environment].name &&
      arc.input.resource_group == azurerm_resource_group.environment[environment].name &&
      arc.input.environment == environment
    ]) && length(terraform_data.arc) == 3
    error_message = "Every AKS cluster must have its own Arc onboarding resource in the matching resource group."
  }

  assert {
    condition = length(toset(concat(
      [for network in azurerm_virtual_network.environment : one(network.address_space)],
      [for cluster in azurerm_kubernetes_cluster.cluster : cluster.network_profile[0].pod_cidr],
      [for cluster in azurerm_kubernetes_cluster.cluster : cluster.network_profile[0].service_cidr]
    ))) == 9
    error_message = "Node VNets, pod ranges and service ranges must use nine distinct /16 networks."
  }
}

run "custom_demo_settings" {
  command = plan

  variables {
    prefix                          = "course820"
    node_count                      = 2
    api_server_authorized_ip_ranges = ["203.0.113.10/32"]
  }

  assert {
    condition = alltrue([
      for environment, cluster in azurerm_kubernetes_cluster.cluster :
      cluster.name == "aks-course820-${environment}" &&
      cluster.default_node_pool[0].node_count == 2 &&
      cluster.api_server_access_profile[0].authorized_ip_ranges == toset(["203.0.113.10/32"])
    ])
    error_message = "Naming, node count and API access overrides must apply to all environments."
  }
}