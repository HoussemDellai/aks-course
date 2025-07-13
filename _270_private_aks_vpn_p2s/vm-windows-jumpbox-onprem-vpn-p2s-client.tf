resource "azurerm_resource_group" "rg-onprem" {
  name     = "rg-onprem-vpn-p2s-${var.prefix}"
  location = "swedencentral"
}

resource "azurerm_virtual_network" "vnet-onprem" {
  name                = "vnet-onprem"
  resource_group_name = azurerm_resource_group.rg-onprem.name
  location            = azurerm_resource_group.rg-onprem.location
  address_space       = ["10.100.0.0/16"]
  dns_servers         = [azurerm_firewall.firewall.ip_configuration.0.private_ip_address]
}

resource "azurerm_subnet" "snet-onprem-vm" {
  name                 = "snet-onprem-vm"
  resource_group_name  = azurerm_virtual_network.vnet-onprem.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-onprem.name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_network_security_group" "nsg-vm-onprem" {
  name                = "nsg-vm-onprem"
  location            = azurerm_resource_group.rg-onprem.location
  resource_group_name = azurerm_resource_group.rg-onprem.name
}

resource "azurerm_network_security_rule" "allow-rdp" {
  network_security_group_name  = azurerm_network_security_group.nsg-vm-onprem.name
  resource_group_name          = azurerm_network_security_group.nsg-vm-onprem.resource_group_name
  name                         = "allow-rdp"
  access                       = "Allow"
  priority                     = 1000
  direction                    = "Inbound"
  protocol                     = "Tcp"
  source_address_prefix        = "*"
  source_port_range            = "*"
  destination_address_prefixes = ["0.0.0.0/0"]
  destination_port_range       = "3389"
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.snet-onprem-vm.id
  network_security_group_id = azurerm_network_security_group.nsg-vm-onprem.id
}

resource "azurerm_public_ip" "pip-win-vm-onprem" {
  name                = "pip-win-vm-onprem"
  location            = azurerm_resource_group.rg-onprem.location
  resource_group_name = azurerm_resource_group.rg-onprem.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic-vm-onprem" {
  name                = "nic-vm"
  resource_group_name = azurerm_resource_group.rg-onprem.name
  location            = azurerm_resource_group.rg-onprem.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-onprem-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-win-vm-onprem.id
  }
}

resource "azurerm_windows_virtual_machine" "vm-windows-onprem" {
  name                  = "vm-win-onprem"
  resource_group_name   = azurerm_resource_group.rg-onprem.name
  location              = azurerm_resource_group.rg-onprem.location
  size                  = "Standard_D4ads_v6"
  admin_username        = "azureuser"
  admin_password        = "@Aa123456789"
  network_interface_ids = [azurerm_network_interface.nic-vm-onprem.id]
  priority              = "Spot"
  eviction_policy       = "Delete"
  disk_controller_type  = "NVMe" # "SCSI" # "IDE" # "SCSI" is the default value. "NVMe" is only supported for Ephemeral OS Disk.

  # custom_data = filebase64("./install-tools.sh")

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "os-disk-vm"
    caching              = "ReadOnly"        # "ReadWrite" # None, ReadOnly and ReadWrite.
    storage_account_type = "StandardSSD_LRS" # "Standard_LRS"
    disk_size_gb         = 128

    diff_disk_settings {
      option    = "Local"    # Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is Local.
      placement = "NvmeDisk" # "ResourceDisk" # "CacheDisk" # Specifies the Ephemeral Disk Placement for the OS Disk. NvmeDisk can only be used for v6 VMs
    }
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_role_assignment" "vm-contributor-onprem" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine.vm-windows-onprem.identity[0].principal_id
}

output "vm_windows_onprem_public_ip" {
  value = azurerm_public_ip.pip-win-vm-onprem.ip_address
}