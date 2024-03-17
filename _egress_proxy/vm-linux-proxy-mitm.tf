resource "azurerm_public_ip" "pip-vm-proxy" {
  name                = "pip-vm-proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic-vm-proxy" {
  name                = "nic-vm-proxy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-vm-proxy.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-proxy" {
  name                            = "vm-linux-mitmproxy"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = "@Aa123456789"
  network_interface_ids           = [azurerm_network_interface.nic-vm-proxy.id]
  priority                        = "Spot"
  eviction_policy                 = "Deallocate"

  # custom_data = filebase64("./install-mitmproxy.sh")

  os_disk {
    name                 = "os-disk-vm"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

# nsg
resource "azurerm_network_security_group" "nsg-vm-proxy" {
  name                = "nsg-vm-proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# nsg rule
resource "azurerm_network_security_rule" "nsg-allow-ssh" {
  name                        = "nsg-allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-vm-proxy.name
}

resource "azurerm_network_security_rule" "nsg-allow-http" {
  name                        = "nsg-allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-vm-proxy.name
}

# attach nsg to NIC
resource "azurerm_network_interface_security_group_association" "nsg-association-vm-proxy" {
  network_interface_id      = azurerm_network_interface.nic-vm-proxy.id
  network_security_group_id = azurerm_network_security_group.nsg-vm-proxy.id
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip-vm-proxy.ip_address
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic-vm-proxy.private_ip_address
}