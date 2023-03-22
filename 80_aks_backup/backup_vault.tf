resource "azurerm_resource_group" "rg_backup_vault" {
  name     = "rg-backup-vault-aks"
  location = "West Europe"
}

resource azurerm_data_protection_backup_vault backup_vault {
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
resource "azurerm_role_assignment" "aks_backup_extension" {
  scope                = azurerm_storage_account.sa_backup_aks.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = "07992e38-78f8-4759-931e-1dc78cf22db2"
}

# AKS 02 backup extension Storage Account Contributor on SA 
resource "azurerm_role_assignment" "aks_02_backup_extension" {
  scope                = azurerm_storage_account.sa_backup_aks.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = "01a8d425-8eb5-4210-b87d-6a9f3b7e1458"
}

# AKS 01 Contributor on Storage Account
resource "azurerm_role_assignment" "aks_sa" {
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

# az k8s-extension show --name azure-aks-backup --cluster-name aksclustername --resource-group aksclusterresourcegroup --cluster-type managedClusters --query aksAssignedIdentity.principalId --output tsv

# backup instance for AKS


# resource "null_resource" "install_dataprotection_aks_01" {

#   provisioner "local-exec" {
#     interpreter = ["PowerShell", "-Command"]
#     on_failure  = continue # fail
#     when        = create
#     command     = <<-EOT

#       az dataprotection backup-instance create --backup-instance backupinstance.json
#                                                --resource-group ${azurerm_resource_group.rg_backup_vault.name}
#                                                --vault-name     
#     EOT
#   }

#   triggers = {
#     "key" = "value1"
#   }

#   depends_on = [
#     azurerm_kubernetes_cluster.aks_01
#   ]
# }

resource azapi_resource backup_policy_aks_01 {
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

resource azapi_resource backup_instance_aks_01 {
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
              excludedNamespaces = null,
              includedResourceTypes = null,
              excludedResourceTypes = null,
              labelSelectors = null
            }
          ]
        }
      },
    }
  })
}

#         {
#             "type": "Microsoft.DataProtection/backupVaults/backupInstances",
#             "apiVersion": "2023-01-01",
#             "name": "[concat(parameters('BackupVaults_backup_vault_name'), '/aks-1-aks-1-21da7d16-e7e3-42ea-8d4c-34db382660ae')]",
#             "dependsOn": [
#                 "[resourceId('Microsoft.DataProtection/backupVaults', parameters('BackupVaults_backup_vault_name'))]",
#                 "[resourceId('Microsoft.DataProtection/BackupVaults/backupPolicies', parameters('BackupVaults_backup_vault_name'), 'policy-aks')]"
#             ],
#             "properties": {
#                 "friendlyName": "aks-1\\backup-instance-aks",
#                 "dataSourceInfo": {
#                     "resourceID": "[parameters('managedClusters_aks_1_externalid')]",
#                     "resourceUri": "[parameters('managedClusters_aks_1_externalid')]",
#                     "datasourceType": "Microsoft.ContainerService/managedClusters",
#                     "resourceName": "aks-1",
#                     "resourceType": "Microsoft.ContainerService/managedClusters",
#                     "resourceLocation": "westeurope",
#                     "objectType": "Datasource"
#                 },
#                 "dataSourceSetInfo": {
#                     "resourceID": "[parameters('managedClusters_aks_1_externalid')]",
#                     "resourceUri": "[parameters('managedClusters_aks_1_externalid')]",
#                     "datasourceType": "Microsoft.ContainerService/managedClusters",
#                     "resourceName": "aks-1",
#                     "resourceType": "Microsoft.ContainerService/managedClusters",
#                     "resourceLocation": "westeurope",
#                     "objectType": "DatasourceSet"
#                 },
#                 "policyInfo": {
#                     "policyId": "[resourceId('Microsoft.DataProtection/BackupVaults/backupPolicies', parameters('BackupVaults_backup_vault_name'), 'policy-aks')]",
#                     "policyParameters": {
#                         "dataStoreParametersList": [
#                             {
#                                 "objectType": "AzureOperationalStoreParameters",
#                                 "dataStoreType": "OperationalStore",
#                                 "resourceGroupId": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-backup-storage"
#                             }
#                         ],
#                         "backupDatasourceParametersList": [
#                             {
#                                 "objectType": "KubernetesClusterBackupDatasourceParameters",
#                                 "snapshotVolumes": true,
#                                 "includeClusterScopeResources": true
#                             }
#                         ]
#                     }
#                 },
#                 "objectType": "BackupInstance"
#             }
#         },

# # backup policy for AKS
