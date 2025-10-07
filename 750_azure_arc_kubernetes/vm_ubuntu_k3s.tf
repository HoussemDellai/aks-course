module "azure_ubuntu_vm_k3s_001" {
  source = "./modules/k3s"

  prefix                    = "${var.prefix}-001"
  client_id                 = var.client_id
  client_secret             = var.client_secret
  tenant_id                 = var.tenant_id
  location                  = var.location
  rg_name                   = "rg-arc-k8s-${var.location}-${var.prefix}-001"
  vm_name                   = "vm-ubuntu-k3s-${var.location}-${var.prefix}-001"
  firewall_private_ip       = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  vnet_address_space        = "10.10.1.0/24"
  subnet_address_prefix     = "10.10.1.0/24"
  vnet_hub_rg               = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_name             = azurerm_virtual_network.vnet-hub.name
  vnet_hub_id               = azurerm_virtual_network.vnet-hub.id
  prometheus_resource_id    = azurerm_monitor_workspace.prometheus.id
  grafana_resource_id       = azurerm_dashboard_grafana.grafana.id
  log_analytics_resource_id = azurerm_log_analytics_workspace.workspace.id
}

module "azure_ubuntu_vm_k3s_002" {
  source = "./modules/k3s"

  prefix                    = "${var.prefix}-002"
  client_id                 = var.client_id
  client_secret             = var.client_secret
  tenant_id                 = var.tenant_id
  location                  = var.location
  rg_name                   = "rg-arc-k8s-${var.location}-${var.prefix}-002"
  vm_name                   = "vm-ubuntu-k3s-${var.location}-${var.prefix}-002"
  firewall_private_ip       = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  vnet_address_space        = "10.10.2.0/24"
  subnet_address_prefix     = "10.10.2.0/24"
  vnet_hub_rg               = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_name             = azurerm_virtual_network.vnet-hub.name
  vnet_hub_id               = azurerm_virtual_network.vnet-hub.id
  prometheus_resource_id    = azurerm_monitor_workspace.prometheus.id
  grafana_resource_id       = azurerm_dashboard_grafana.grafana.id
  log_analytics_resource_id = azurerm_log_analytics_workspace.workspace.id

  # depends_on = [ module.azure_ubuntu_vm_k3s_001 ]
}

module "azure_ubuntu_vm_k3s_003" {
  source = "./modules/k3s"

  prefix                    = "${var.prefix}-003"
  client_id                 = var.client_id
  client_secret             = var.client_secret
  tenant_id                 = var.tenant_id
  location                  = var.location
  rg_name                   = "rg-arc-k8s-${var.location}-${var.prefix}-003"
  vm_name                   = "vm-ubuntu-k3s-${var.location}-${var.prefix}-003"
  firewall_private_ip       = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  vnet_address_space        = "10.10.3.0/24"
  subnet_address_prefix     = "10.10.3.0/24"
  vnet_hub_rg               = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_name             = azurerm_virtual_network.vnet-hub.name
  vnet_hub_id               = azurerm_virtual_network.vnet-hub.id
  prometheus_resource_id    = azurerm_monitor_workspace.prometheus.id
  grafana_resource_id       = azurerm_dashboard_grafana.grafana.id
  log_analytics_resource_id = azurerm_log_analytics_workspace.workspace.id
}

module "azure_ubuntu_vm_k3s_004" {
  source = "./modules/k3s"

  prefix                    = "${var.prefix}-004"
  client_id                 = var.client_id
  client_secret             = var.client_secret
  tenant_id                 = var.tenant_id
  location                  = var.location
  rg_name                   = "rg-arc-k8s-${var.location}-${var.prefix}-004"
  vm_name                   = "vm-ubuntu-k3s-${var.location}-${var.prefix}-004"
  firewall_private_ip       = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  vnet_address_space        = "10.10.4.0/24"
  subnet_address_prefix     = "10.10.4.0/24"
  vnet_hub_rg               = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_name             = azurerm_virtual_network.vnet-hub.name
  vnet_hub_id               = azurerm_virtual_network.vnet-hub.id
  prometheus_resource_id    = azurerm_monitor_workspace.prometheus.id
  grafana_resource_id       = azurerm_dashboard_grafana.grafana.id
  log_analytics_resource_id = azurerm_log_analytics_workspace.workspace.id
}

module "azure_ubuntu_vm_k3s_005" {
  source = "./modules/k3s"

  prefix                    = "${var.prefix}-005"
  client_id                 = var.client_id
  client_secret             = var.client_secret
  tenant_id                 = var.tenant_id
  location                  = var.location
  rg_name                   = "rg-arc-k8s-${var.location}-${var.prefix}-005"
  vm_name                   = "vm-ubuntu-k3s-${var.location}-${var.prefix}-005"
  firewall_private_ip       = azurerm_firewall.firewall.ip_configuration.0.private_ip_address
  vnet_address_space        = "10.10.5.0/24"
  subnet_address_prefix     = "10.10.5.0/24"
  vnet_hub_rg               = azurerm_virtual_network.vnet-hub.resource_group_name
  vnet_hub_name             = azurerm_virtual_network.vnet-hub.name
  vnet_hub_id               = azurerm_virtual_network.vnet-hub.id
  prometheus_resource_id    = azurerm_monitor_workspace.prometheus.id
  grafana_resource_id       = azurerm_dashboard_grafana.grafana.id
  log_analytics_resource_id = azurerm_log_analytics_workspace.workspace.id
}

output "azure_ubuntu_vm_k3s_001_pip" {
  value = module.azure_ubuntu_vm_k3s_001.vm_pip
}

output "azure_ubuntu_vm_k3s_002_pip" {
  value = module.azure_ubuntu_vm_k3s_002.vm_pip
}

output "azure_ubuntu_vm_k3s_003_pip" {
  value = module.azure_ubuntu_vm_k3s_003.vm_pip
}

output "azure_ubuntu_vm_k3s_004_pip" {
  value = module.azure_ubuntu_vm_k3s_004.vm_pip
}

output "azure_ubuntu_vm_k3s_005_pip" {
  value = module.azure_ubuntu_vm_k3s_005.vm_pip
}

output "azure_ubuntu_vm_k3s_001_private_ip" {
  value = module.azure_ubuntu_vm_k3s_001.vm_private_ip
}

output "azure_ubuntu_vm_k3s_002_private_ip" {
  value = module.azure_ubuntu_vm_k3s_002.vm_private_ip
}

output "azure_ubuntu_vm_k3s_003_private_ip" {
  value = module.azure_ubuntu_vm_k3s_003.vm_private_ip
}

output "azure_ubuntu_vm_k3s_004_private_ip" {
  value = module.azure_ubuntu_vm_k3s_004.vm_private_ip
}

output "azure_ubuntu_vm_k3s_005_private_ip" {
  value = module.azure_ubuntu_vm_k3s_005.vm_private_ip
}
