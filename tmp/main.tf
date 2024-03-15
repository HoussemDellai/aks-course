data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West Europe"
}

resource "azurerm_resource_group" "snap" {
  name     = "example-snap"
  location = "West Europe"
}

resource "azurerm_data_protection_backup_vault" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "dns"

  default_node_pool {
    name                   = "default"
    node_count             = 1
    vm_size                = "Standard_DS2_v2"
    # enable_host_encryption = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "aks_cluster_trusted_access" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  name                  = "example"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = azurerm_data_protection_backup_vault.example.id
}

resource "azurerm_storage_account" "example" {
  name                     = "examplest19735"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "example"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_kubernetes_cluster_extension" "example" {
  name              = "example"
  cluster_id        = azurerm_kubernetes_cluster.example.id
  extension_type    = "Microsoft.DataProtection.Kubernetes"
  release_train     = "stable"
  release_namespace = "dataprotection-microsoft"
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                = azurerm_storage_container.example.name
    "configuration.backupStorageLocation.config.resourceGroup"  = azurerm_resource_group.example.name
    "configuration.backupStorageLocation.config.storageAccount" = azurerm_storage_account.example.name
    "configuration.backupStorageLocation.config.subscriptionId" = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                      = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_role_assignment" "extension_and_storage_account_permission" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.example.aks_assigned_identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_read_on_cluster" {
  scope                = azurerm_kubernetes_cluster.example.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.example.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_read_on_snap_rg" {
  scope                = azurerm_resource_group.snap.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.example.identity[0].principal_id
}

resource "azurerm_role_assignment" "cluster_msi_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.snap.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.example.identity[0].principal_id
}

resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  vault_name          = azurerm_data_protection_backup_vault.example.name

  backup_repeating_time_intervals = ["R/2023-05-23T02:30:00+00:00/P1W"]

  retention_rule {
    name     = "Daily"
    priority = 25

    life_cycle {
      duration        = "P84D"
      data_store_type = "OperationalStore"
    }

    criteria {
      days_of_week           = ["Thursday"]
      months_of_year         = ["November"]
      weeks_of_month         = ["First"]
      scheduled_backup_times = ["2023-05-23T02:30:00Z"]
    }
  }

  default_retention_rule {
    life_cycle {
      duration        = "P14D"
      data_store_type = "OperationalStore"
    }
  }
}

resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "example" {
  name                         = "example"
  location                     = azurerm_resource_group.example.location
  vault_id                     = azurerm_data_protection_backup_vault.example.id
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.example.id
  snapshot_resource_group_name = azurerm_resource_group.snap.name
  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.example.id

  backup_datasource_parameters {
    excluded_namespaces              = ["test-excluded-namespaces"]
    excluded_resource_types          = ["exvolumesnapshotcontents.snapshot.storage.k8s.io"]
    cluster_scoped_resources_enabled = true
    included_namespaces              = ["test-included-namespaces"]
    included_resource_types          = ["involumesnapshotcontents.snapshot.storage.k8s.io"]
    label_selectors                  = ["kubernetes.io/metadata.name:test"]
    volume_snapshot_enabled          = true
  }

  depends_on = [
    azurerm_role_assignment.extension_and_storage_account_permission,
  ]
}