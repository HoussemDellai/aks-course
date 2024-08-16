# resource "azurerm_role_assignment" "example" {
#   role_definition_name = "Role Based Access Control Administrator"
#   scope                = data.azurerm_subscription.primary.id
#   principal_id         = data.azurerm_client_config.example.object_id
#   principal_type       = "ServicePrincipal"
#   description          = "Role Based Access Control Administrator role assignment with ABAC Condition."
#   condition_version    = "2.0"
#   condition            = <<-EOT
# (
#  (
#   !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
#  )
#  OR
#  (
#   @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${basename(data.azurerm_role_definition.builtin.role_definition_id)}}
#  )
# )
# AND
# (
#  (
#   !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
#  )
#  OR
#  (
#   @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${basename(data.azurerm_role_definition.builtin.role_definition_id)}}
#  )
# )
# EOT
# }