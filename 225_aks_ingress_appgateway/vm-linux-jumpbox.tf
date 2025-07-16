resource "azurerm_network_interface" "nic-vm-linux" {
  name                = "nic-vm-linux"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null # azurerm_public_ip.pip-vm-linux.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-linux-jumpbox" {
  name                            = "vm-linux-jumpbox"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2ads_v6"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = "@Aa123456789"
  network_interface_ids           = [azurerm_network_interface.nic-vm-linux.id]
  priority                        = "Spot"
  eviction_policy                 = "Delete"
  disk_controller_type            = "NVMe" # "SCSI" # "IDE" # "SCSI" is the default value. "NVMe" is only supported for Ephemeral OS Disk.

  os_disk {
    name                 = "os-disk-vm-linux"
    caching              = "ReadOnly"        # "ReadWrite" # None, ReadOnly and ReadWrite.
    storage_account_type = "StandardSSD_LRS" # "Standard_LRS"
    disk_size_gb         = 64

    diff_disk_settings {
      option    = "Local"    # Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is Local.
      placement = "NvmeDisk" # "ResourceDisk" # "CacheDisk" # Specifies the Ephemeral Disk Placement for the OS Disk. NvmeDisk can only be used for v6 VMs
    }
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-25_04" # "0001-com-ubuntu-server-jammy"
    sku       = "minimal"      # "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}