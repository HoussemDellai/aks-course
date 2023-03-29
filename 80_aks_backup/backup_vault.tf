resource "azurerm_resource_group" "rg_backup_vault" {
  name     = "rg-backup-vault-aks"
  location = "West Europe"
}

resource "azurerm_data_protection_backup_vault" "backup_vault" {
  name                = "backup-vault-aks"
  resource_group_name = azurerm_resource_group.rg_backup_vault.name
  location            = azurerm_resource_group.rg_backup_vault.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }
}

# AKS 01 backup extension Storage Account Contributor on SA 
resource "azurerm_role_assignment" "aks_01_backup_extension" {
  scope                = azurerm_storage_account.sa_backup_aks.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_user_assigned_identity.mi_ext_aks_01.principal_id #todo (MI ext-xxxxxxxxxxx)
}
# az k8s-extension show --name azure-aks-backup --cluster-name aksclustername --resource-group aksclusterresourcegroup --cluster-type managedClusters --query aksAssignedIdentity.principalId --output tsv

# AKS 02 backup extension Storage Account Contributor on SA 
resource "azurerm_role_assignment" "aks_02_backup_extension" {
  scope                = azurerm_storage_account.sa_backup_aks.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_user_assigned_identity.mi_ext_aks_02.principal_id #todo
}
# az k8s-extension show --name azure-aks-backup --cluster-name aksclustername --resource-group aksclusterresourcegroup --cluster-type managedClusters --query aksAssignedIdentity.principalId --output tsv

# AKS 01 Contributor on Storage Account
resource "azurerm_role_assignment" "aks_01_sa" {
  scope                = azurerm_resource_group.rg_backup_storage.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_01.identity.0.principal_id
}

# AKS 02 Contributor on Storage Account
resource "azurerm_role_assignment" "aks_02_sa" {
  scope                = azurerm_resource_group.rg_backup_storage.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_02.identity.0.principal_id
}

# Backup Vault Reader on AKS 01
resource "azurerm_role_assignment" "backup_vault_reader_on_aks_01" {
  scope                = azurerm_kubernetes_cluster.aks_01.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity.0.principal_id
}

# Backup Vault Reader on AKS 02
resource "azurerm_role_assignment" "backup_vault_reader_on_aks_02" {
  scope                = azurerm_kubernetes_cluster.aks_02.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity.0.principal_id
}

# Backup Vault Reader on Storage Account RG
resource "azurerm_role_assignment" "backup_vault_reader_on_sa_rg" {
  scope                = azurerm_resource_group.rg_backup_storage.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity.0.principal_id
}

resource "azapi_resource" "backup_policy_aks_01" {
  type      = "Microsoft.DataProtection/backupVaults/backupPolicies@2023-01-01"
  name      = "backup-policy-aks-01"
  parent_id = azurerm_data_protection_backup_vault.backup_vault.id

  body = jsonencode({
    properties = {
      policyRules = [
        {
          lifecycles = [
            {
              deleteAfter = {
                objectType = "AbsoluteDeleteOption",
                duration   = "P7D"
              },
              targetDataStoreCopySettings = [],
              sourceDataStore = {
                dataStoreType = "OperationalStore",
                objectType    = "DataStoreInfoBase"
              }
            }
          ],
          isDefault  = true,
          name       = "Default",
          objectType = "AzureRetentionRule"
        },
        {
          backupParameters = {
            backupType = "Incremental",
            objectType = "AzureBackupParams"
          },
          trigger = {
            schedule = {
              repeatingTimeIntervals = [
                "R/2023-03-22T07:20:34+00:00/PT4H"
              ],
              timeZone = "UTC"
            },
            taggingCriteria = [
              {
                tagInfo = {
                  tagName = "Default"
                },
                taggingPriority = 99,
                isDefault       = true
              }
            ],
            objectType = "ScheduleBasedTriggerContext"
          },
          dataStore = {
            dataStoreType = "OperationalStore",
            objectType    = "DataStoreInfoBase"
          },
          name       = "BackupHourly",
          objectType = "AzureBackupRule"
        }
      ],
      datasourceTypes = [
        "Microsoft.ContainerService/managedClusters"
      ],
      objectType = "BackupPolicy"
    }
  })
}

resource "azapi_resource" "backup_instance_aks_01" {
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2023-01-01"
  name      = "backup-instance-aks-01"
  parent_id = azurerm_data_protection_backup_vault.backup_vault.id

  body = jsonencode({
    properties = {
      friendlyName = "aks-1\\backup-instance-aks-01"
      objectType   = "BackupInstance"
      dataSourceInfo = {
        resourceID       = azurerm_kubernetes_cluster.aks_01.id,
        resourceUri      = azurerm_kubernetes_cluster.aks_01.id,
        datasourceType   = "Microsoft.ContainerService/managedClusters",
        resourceName     = azurerm_kubernetes_cluster.aks_01.name,
        resourceType     = "Microsoft.ContainerService/managedClusters",
        resourceLocation = "westeurope",
        objectType       = "Datasource",
        # resourceProperties = {
        #   objectType = null
        # }
      },
      dataSourceSetInfo = {
        resourceID       = azurerm_kubernetes_cluster.aks_01.id,
        resourceUri      = azurerm_kubernetes_cluster.aks_01.id,
        datasourceType   = "Microsoft.ContainerService/managedClusters",
        resourceName     = azurerm_kubernetes_cluster.aks_01.name,
        resourceType     = "Microsoft.ContainerService/managedClusters",
        resourceLocation = "westeurope",
        objectType       = "Datasource"
      },
      policyInfo = {
        policyId = azapi_resource.backup_policy_aks_01.id,
        policyParameters = {
          dataStoreParametersList = [
            {
              objectType      = "AzureOperationalStoreParameters",
              dataStoreType   = "OperationalStore",
              resourceGroupId = azurerm_resource_group.rg_backup_storage.id
            }
          ],
          backupDatasourceParametersList = [
            {
              objectType                   = "KubernetesClusterBackupDatasourceParameters",
              snapshotVolumes              = true,
              includeClusterScopeResources = true,
              includedNamespaces = [
                "default"
              ],
              excludedNamespaces    = null,
              includedResourceTypes = null,
              excludedResourceTypes = null,
              labelSelectors        = null
            }
          ]
        }
      },
    }
  })
}