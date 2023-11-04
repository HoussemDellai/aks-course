resource "azurerm_user_assigned_identity" "identity" {
  name                = "identity-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_B2s_v2"
    vnet_subnet_id = azurerm_subnet.subnet.id
    zones          = [1, 2, 3]
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer" # "userAssignedNATGateway" # 
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }
}