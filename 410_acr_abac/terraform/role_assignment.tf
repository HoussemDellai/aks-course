resource "azurerm_role_assignment" "aca-app2" {
  role_definition_name = "ACR Repository Reader"
  scope                = azurerm_container_registry.acr.id
  principal_id         = azurerm_user_assigned_identity.identity_aca_app2.principal_id
  principal_type       = "ServicePrincipal" # User
  description          = "Allows for read access to Azure Container Registry repositories, but excluding catalog listing."
  condition_version    = "2.0"
  condition            = <<-EOT
(
 (
  !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/content/read'})
  AND
  !(ActionMatches{'Microsoft.ContainerRegistry/registries/repositories/metadata/read'})
 )
 OR 
 (
  @Resource[Microsoft.ContainerRegistry/registries/repositories:name] StringStartsWithIgnoreCase 'team2/'
 )
)
EOT
}