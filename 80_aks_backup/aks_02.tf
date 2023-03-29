resource "azurerm_resource_group" "rg_aks_02" {
  name     = "rg-aks-02"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "aks_02" {
  name                = "aks-02"
  location            = azurerm_resource_group.rg_aks_02.location
  resource_group_name = azurerm_resource_group.rg_aks_02.name
  kubernetes_version  = "1.25.5"
  dns_prefix          = "aks-02"

  default_node_pool {
    name       = "systempool"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  storage_profile {
    disk_driver_enabled         = true
    snapshot_controller_enabled = true
  }
}

resource "null_resource" "install_dataprotection_aks_02" {

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue # fail
    when        = create
    command     = <<-EOT

        az extension add --name k8s-extension

        az k8s-extension create --name azure-aks-backup `
        --extension-type Microsoft.DataProtection.Kubernetes `
        --scope cluster `
        --cluster-type managedClusters `
        --cluster-name ${azurerm_kubernetes_cluster.aks_02.name} `
        --resource-group ${azurerm_kubernetes_cluster.aks_02.resource_group_name} `
        --release-train stable `
        --configuration-settings `
        blobContainer=${azurerm_storage_container.container_backup_aks.name} `
        storageAccount=${azurerm_storage_account.sa_backup_aks.name} `
        storageAccountResourceGroup=${azurerm_storage_account.sa_backup_aks.resource_group_name} `
        storageAccountSubscriptionId=${data.azurerm_client_config.current.subscription_id}

        # View Backup Extension installation status

        az k8s-extension show --name azure-aks-backup `
           --cluster-type managedClusters `
           --cluster-name ${azurerm_kubernetes_cluster.aks_02.name} `
           -g ${azurerm_kubernetes_cluster.aks_02.resource_group_name}

    EOT
  }

  triggers = {
    "key" = "value1"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks_02
  ]
}

resource "null_resource" "configure_trustedaccess_aks_02" {

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    on_failure  = continue
    when        = create
    command     = <<-EOT

        az aks trustedaccess rolebinding create `
           -g ${azurerm_kubernetes_cluster.aks_02.resource_group_name} `
           --cluster-name ${azurerm_kubernetes_cluster.aks_02.name} `
           -n trustedaccess `
           --source-resource-id ${azurerm_data_protection_backup_vault.backup_vault.id} `
           --roles Microsoft.DataProtection/backupVaults/backup-operator

    EOT
  }

  triggers = {
    "key" = "value2"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks_02,
    null_resource.install_dataprotection_aks_02
  ]
}