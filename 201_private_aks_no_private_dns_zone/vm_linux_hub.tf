resource "azurerm_public_ip" "pip-vm-hub" {
  name                = "pip-vm-hub"
  resource_group_name = azurerm_resource_group.rg-hub.name
  location            = azurerm_resource_group.rg-hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic-vm-hub" {
  name                  = "nic-vm-hub"
  resource_group_name   = azurerm_resource_group.rg-hub.name
  location              = azurerm_resource_group.rg-hub.location
  ip_forwarding_enabled = false

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-hub-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-vm-hub.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-hub" {
  name                            = "vm-linux-hub"
  resource_group_name             = azurerm_resource_group.rg-hub.name
  location                        = azurerm_resource_group.rg-hub.location
  size                            = "Standard_D4ads_v6"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = "@Aa123456789"
  network_interface_ids           = [azurerm_network_interface.nic-vm-hub.id]
  priority                        = "Spot"
  eviction_policy                 = "Delete"
  disk_controller_type            = "NVMe" # "SCSI" # "IDE" # "SCSI" is the default value. "NVMe" is only supported for Ephemeral OS Disk.

  custom_data = filebase64("./install-tools.sh")

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity-vm-hub.id]
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
    publisher = "canonical"
    offer     = "ubuntu-25_04" # "0001-com-ubuntu-server-jammy"
    sku       = "minimal" # "22_04-lts-gen2"
    version   = "latest"
  }
  
  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_user_assigned_identity" "identity-vm-hub" {
  name                = "identity-vm-hub"
  resource_group_name = azurerm_resource_group.rg-hub.name
  location            = azurerm_resource_group.rg-hub.location
}

resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-vm-hub.principal_id
}

data "azurerm_subscription" "current" {}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-vm-hub"
  location            = azurerm_resource_group.rg-hub.location
  resource_group_name = azurerm_resource_group.rg-hub.name
}

resource "azurerm_network_security_rule" "allow-ssh" {
  resource_group_name          = azurerm_resource_group.rg-hub.name
  network_security_group_name  = azurerm_network_security_group.nsg.name
  name                         = "allow-ssh"
  access                       = "Allow"
  priority                     = 1000
  direction                    = "Inbound"
  protocol                     = "Tcp"
  source_address_prefix        = "Internet"
  source_port_range            = "*"
  destination_address_prefixes = [azurerm_linux_virtual_machine.vm-hub.private_ip_address]
  destination_port_range       = "22"
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.snet-hub-vm.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
