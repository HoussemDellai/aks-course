resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "backup-instance" {
  name                         = "backup-instance"
  location                     = azurerm_resource_group.rg.location
  vault_id                     = azurerm_data_protection_backup_vault.backup-vault.id
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks.id
  snapshot_resource_group_name = azurerm_resource_group.rg-backup.name
  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.backup-policy-aks.id

  backup_datasource_parameters {
    excluded_namespaces              = ["test-excluded-namespaces"]
    excluded_resource_types          = ["exvolumesnapshotcontents.snapshot.storage.k8s.io"]
    cluster_scoped_resources_enabled = true
    included_namespaces              = ["*"] # ["test-included-namespaces"]
    included_resource_types          = ["*"] # ["involumesnapshotcontents.snapshot.storage.k8s.io"]
    label_selectors                  = ["*"] # ["kubernetes.io/metadata.name:test"]
    volume_snapshot_enabled          = true
  }

  depends_on = [
    azurerm_role_assignment.extension_and_storage_account_permission,
  ]
}