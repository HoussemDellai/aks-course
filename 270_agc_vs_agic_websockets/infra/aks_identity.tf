resource "azurerm_user_assigned_identity" "identity_aks" {
  name                = "identity-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "role_identity_aks_network_contributor" {
  scope                            = azurerm_virtual_network.vnet_spoke_aks.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_identity_aks_network_contributor_subnet_apiserver" {
  scope                            = azurerm_subnet.snet_aks_apiserver.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
  skip_service_principal_aad_check = true
}

# resource "azurerm_role_assignment" "role_identity_aks_mi_operator" {
#   scope                            = azurerm_user_assigned_identity.identity-kubelet.id
#   role_definition_name             = "Managed Identity Operator"
#   principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
#   skip_service_principal_aad_check = true
# }

# resource "azurerm_role_assignment" "role_identity_aks_contributor" {
#   scope                            = azurerm_resource_group.rg.id
#   role_definition_name             = "Contributor"
#   principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
#   skip_service_principal_aad_check = true
# }

# Assign Network Contributor to the API server subnet
# az role assignment create --scope <apiserver-subnet-resource-id> \
#     --role "Network Contributor" \
#     --assignee <managed-identity-client-id>

# # Role Assignments for Control Plane MSI
# resource "azurerm_role_assignment" "role_identity_aks_contributor_routetable" {
#   count                = var.enable_firewall_as_dns_server ? 1 : 0
#   scope                = data.terraform_remote_state.spoke_aks.outputs.route_table.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.identity_aks.principal_id
# }

# resource "azurerm_role_assignment" "role_identity_aks_network_contributor_routetable" {
#   count                = var.enable_private_cluster ? 1 : 0
#   scope                = data.terraform_remote_state.hub.0.outputs.dns_zone_aks.id
#   role_definition_name = "Network Contributor"
#   principal_id         = azurerm_user_assigned_identity.identity_aks.principal_id
# }