locals {
  environments = {
    dev = 0
    ppr = 1
    prd = 2
  }
}

resource "azurerm_resource_group" "environment" {
  for_each = local.environments

  name     = "rg-${var.prefix}-${each.key}"
  location = var.location
  tags = {
    environment = each.key
    purpose     = "aks-arc-demo"
    managed_by  = "terraform"
  }
}

resource "azurerm_virtual_network" "environment" {
  for_each = local.environments

  name                = "vnet-${var.prefix}-${each.key}"
  location            = azurerm_resource_group.environment[each.key].location
  resource_group_name = azurerm_resource_group.environment[each.key].name
  address_space       = [cidrsubnet("10.0.0.0/8", 8, each.value)]
  tags                = azurerm_resource_group.environment[each.key].tags
}

resource "azurerm_subnet" "nodes" {
  for_each = local.environments

  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.environment[each.key].name
  virtual_network_name = azurerm_virtual_network.environment[each.key].name
  address_prefixes     = [cidrsubnet(one(azurerm_virtual_network.environment[each.key].address_space), 8, 0)]
}

resource "azurerm_user_assigned_identity" "cluster" {
  for_each = local.environments

  name                = "id-${var.prefix}-${each.key}"
  location            = azurerm_resource_group.environment[each.key].location
  resource_group_name = azurerm_resource_group.environment[each.key].name
  tags                = azurerm_resource_group.environment[each.key].tags
}

resource "azurerm_role_assignment" "network" {
  for_each = local.environments

  scope                = azurerm_subnet.nodes[each.key].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster[each.key].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  for_each = local.environments

  name                              = "aks-${var.prefix}-${each.key}"
  location                          = azurerm_resource_group.environment[each.key].location
  resource_group_name               = azurerm_resource_group.environment[each.key].name
  dns_prefix                        = "${var.prefix}-${each.key}"
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = "Free"
  role_based_access_control_enabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  tags                              = azurerm_resource_group.environment[each.key].tags

  default_node_pool {
    name                        = "system"
    node_count                  = var.node_count
    vm_size                     = var.node_vm_size
    os_sku                      = "AzureLinux"
    vnet_subnet_id              = azurerm_subnet.nodes[each.key].id
    temporary_name_for_rotation = "systemtemp"

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster[each.key].id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
    pod_cidr            = cidrsubnet("10.0.0.0/8", 8, each.value + 100)
    service_cidr        = cidrsubnet("10.0.0.0/8", 8, each.value + 200)
    dns_service_ip      = cidrhost(cidrsubnet("10.0.0.0/8", 8, each.value + 200), 10)
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  depends_on = [azurerm_role_assignment.network]
}