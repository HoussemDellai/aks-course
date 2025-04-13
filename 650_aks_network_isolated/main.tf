# provider "azurerm" {
#   features {}
# }

# variable "resource_group_name" {
#   default = "rg-aks-cluster"
# }

# variable "location" {
#   default = "swedencentral"
# }

# variable "vnet_name" {
#   default = "vnet-spoke"
# }

# variable "aks_subnet_name" {
#   default = "snet-aks"
# }

# variable "acr_subnet_name" {
#   default = "snet-acr"
# }

# variable "registry_name" {
#   default = "acr4aks17"
# }

# variable "cluster_identity_name" {
#   default = "identity-aks-control-plane"
# }

# variable "kubelet_identity_name" {
#   default = "identity-aks-kubelet"
# }

# variable "aks_name" {
#   default = "aks-cluster-network-isolated"
# }

# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

# resource "azurerm_virtual_network" "vnet" {
#   name                = var.vnet_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   address_space       = ["192.168.0.0/16"]
# }

# resource "azurerm_subnet" "aks_subnet" {
#   name                 = var.aks_subnet_name
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["192.168.1.0/24"]
# }

# resource "azurerm_subnet" "acr_subnet" {
#   name                 = var.acr_subnet_name
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["192.168.2.0/24"]
#   private_endpoint_network_policies = "Disabled"
# }

# resource "azurerm_container_registry" "acr" {
#   name                = var.registry_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   sku                 = "Premium"
#   admin_enabled       = false
# }

# resource "azurerm_private_endpoint" "pe_acr" {
#   name                = "pe-acr"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   subnet_id           = azurerm_subnet.acr_subnet.id
#   private_service_connection {
#     name                           = "connection-acr"
#     private_connection_resource_id = azurerm_container_registry.acr.id
#     subresource_names              = ["registry"]
#   }
# }

# resource "azurerm_private_dns_zone" "dns_zone" {
#   name                = "privatelink.azurecr.io"
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
#   name                  = "MyDNSLink"
#   resource_group_name   = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
#   registration_enabled  = false
# }

# resource "azurerm_private_dns_a_record" "dns_record_acr" {
#   name                = var.registry_name
#   zone_name           = azurerm_private_dns_zone.dns_zone.name
#   resource_group_name = azurerm_resource_group.rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.pe_acr.private_ip_address]
# }

# resource "azurerm_private_dns_a_record" "dns_record_data" {
#   name                = "${var.registry_name}.${var.location}.data"
#   zone_name           = azurerm_private_dns_zone.dns_zone.name
#   resource_group_name = azurerm_resource_group.rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.pe_acr.private_ip_address]
# }

# resource "azurerm_user_assigned_identity" "cluster_identity" {
#   name                = var.cluster_identity_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

# resource "azurerm_user_assigned_identity" "kubelet_identity" {
#   name                = var.kubelet_identity_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

# resource "azurerm_role_assignment" "acr_pull" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id
# }

# resource "azurerm_kubernetes_cluster" "aks" {
#   name                = var.aks_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   dns_prefix          = var.aks_name

#   default_node_pool {
#     name       = "default"
#     node_count = 1
#     vm_size    = "Standard_DS2_v2"
#   }

#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       azurerm_user_assigned_identity.cluster_identity.id,
#       azurerm_user_assigned_identity.kubelet_identity.id
#     ]
#   }

#   network_profile {
#     network_plugin = "azure"
#     outbound_type  = "none"
#   }

#   private_cluster_enabled = true
# }
