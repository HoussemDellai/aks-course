resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  kubernetes_version      = "1.30.5"
  dns_prefix              = "aks"
  private_cluster_enabled = false


  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name                        = "systempool"
    temporary_name_for_rotation = "syspool"
    vm_size                     = "standard_l8s_v3" # "Standard_D4s_v5"
    node_count                  = 3
    zones                       = [1, 2, 3]
    vnet_subnet_id              = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings
    ]
  }
}

resource "terraform_data" "aks-get-crdentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
}

resource "terraform_data" "enable-aks-container-storage" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks update --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --enable-azure-container-storage ephemeralDisk --storage-pool-option NVMe" # azureDisk, ephemeralDisk, or elasticSan. NVMe, Temp, all
  }
}

