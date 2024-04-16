resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "aks"
  kubernetes_version      = "1.29.2"
  private_cluster_enabled = false

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name                  = "systemnp"
    node_count            = 2
    vm_size               = "Standard_B2als_v2"
    os_sku                = "AzureLinux"
    vnet_subnet_id        = azurerm_subnet.snet-aks.id
    enable_node_public_ip = false
  }

  identity {
    type = "SystemAssigned"
  }

  web_app_routing {
    dns_zone_id = azurerm_dns_zone.dns_zone.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
    secret_rotation_interval = "2m"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}