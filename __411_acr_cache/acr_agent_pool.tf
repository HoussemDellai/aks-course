# resource "azurerm_container_registry_agent_pool" "acr-agentpool" {
#   name                      = "acr-agentpool"
#   resource_group_name       = azurerm_resource_group.rg.name
#   location                  = "westeurope" # azurerm_resource_group.rg.location # List of available regions for the resource type is 'eastus,westeurope,westus2,southcentralus,canadacentral,centralus,eastasia,eastus2,northeurope,switzerlandnorth'
#   container_registry_name   = azurerm_container_registry.acr.name
#   instance_count            = 1
#   tier                      = "S1" # S1 (2 vCPUs, 3 GiB RAM), S2 (4 vCPUs, 8 GiB RAM), S3 (8 vCPUs, 16 GiB RAM) or I6 (64 vCPUs, 216 GiB RAM, Isolated).
#   virtual_network_subnet_id = azurerm_subnet.snet-acr.id
# }
