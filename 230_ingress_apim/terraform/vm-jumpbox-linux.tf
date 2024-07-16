# resource "azurerm_public_ip" "pip-vm" {
#   name                = "pip-vm"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1"]
# }

# resource "azurerm_network_interface" "nic-vm" {
#   name                = "nic-vm"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.snet-aks.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.pip-vm.id
#   }
# }

# resource "azurerm_linux_virtual_machine" "vm-linux-jumpbox" {
#   name                            = "vm-linux-jumpbox"
#   resource_group_name             = azurerm_resource_group.rg.name
#   location                        = azurerm_resource_group.rg.location
#   size                            = "Standard_B2ats_v2"
#   disable_password_authentication = false
#   admin_username                  = "azureuser"
#   admin_password                  = "@Aa123456789"
#   network_interface_ids           = [azurerm_network_interface.nic-vm.id]
#   priority                        = "Spot"
#   eviction_policy                 = "Deallocate"

#   os_disk {
#     name                 = "os-disk-vm"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   boot_diagnostics {
#     storage_account_uri = null
#   }
# }

# # resource "azurerm_network_security_group" "nsg-vm" {
# #   name                = "nsg-vm"
# #   location            = azurerm_resource_group.rg.location
# #   resource_group_name = azurerm_resource_group.rg.name
# # }

# resource "azurerm_subnet_network_security_group_association" "nsg-snet-aks-association" {
#   subnet_id                 = azurerm_subnet.snet-aks.id
#   network_security_group_id = azurerm_network_security_group.nsg-apim.id
# }

# # resource "azurerm_network_interface_security_group_association" "nsg-vm-association" {
# #   network_interface_id      = azurerm_network_interface.nic-vm.id # azurerm_subnet.snet-aks.id
# #   network_security_group_id = azurerm_network_security_group.nsg-vm.id
# # }

# resource "azurerm_network_security_rule" "allow-inbound-ssh" {
#   name                        = "allow-inbound-ssh"
#   access                      = "Allow"   # Allow
#   priority                    = 1100      # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
#   direction                   = "Inbound" # Inbound
#   protocol                    = "Tcp"     # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
#   source_address_prefix       = "*"       # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
#   source_port_range           = "*"       # between 0 and 65535 or * to match any
#   destination_address_prefix  = "*"
#   destination_port_range      = "22"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.nsg-apim.name
# }

# output "vm-ip" {
#   value = azurerm_public_ip.pip-vm.ip_address
# }
