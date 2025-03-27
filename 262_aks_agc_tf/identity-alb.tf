resource "azurerm_user_assigned_identity" "identity-alb" {
  name                = "identity-alb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "aks-node-rg-reader" {
  scope                = azurerm_kubernetes_cluster.aks.node_resource_group_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.identity-alb.principal_id
}

resource "azurerm_role_assignment" "agc-config-manager" {
  scope                = azurerm_application_load_balancer.agc.id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = azurerm_user_assigned_identity.identity-alb.principal_id
}

resource "azurerm_role_assignment" "agc-network-contributor" {
  scope                = azurerm_subnet.snet-agc.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-alb.principal_id
}

resource "azurerm_federated_identity_credential" "identity-alb" {
  name                = "azure-alb-identity" # ALB Controller requires a federated credential with the name of azure-alb-identity. Any other federated credential name is unsupported.
  parent_id           = azurerm_user_assigned_identity.identity-alb.id
  resource_group_name = azurerm_resource_group.rg.name
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
  audience            = ["api://AzureADTokenExchange"]
}