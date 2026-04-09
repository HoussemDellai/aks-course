# Enabling AGIC on AKS will trigger creation of Managed Identity in MC/Node resource group. 

# Identity needs Network Contributor role over App Gateway's Subnet
resource "azurerm_role_assignment" "role_appgw_network_contributor" {
  scope                = azurerm_subnet.snet_appgw.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway.0.ingress_application_gateway_identity.0.object_id
}

# Identity needs Contributor role over App Gateway
resource "azurerm_role_assignment" "role_appgw_contributor" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.ingress_application_gateway.0.ingress_application_gateway_identity.0.object_id
}