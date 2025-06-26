resource "azurerm_network_interface" "nic-vm" {
  name                = "nic-vm-windows"
  resource_group_name = azurerm_resource_group.rg-jumpbox.name
  location            = azurerm_resource_group.rg-jumpbox.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-aks.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-jumpbox-w11"
  resource_group_name   = azurerm_resource_group.rg-jumpbox.name
  location              = azurerm_resource_group.rg-jumpbox.location
  size                  = "Standard_D4ads_v6" # "Standard_B2ats_v2"
  admin_username        = "azureuser"
  admin_password        = "@Aa123456789"
  network_interface_ids = [azurerm_network_interface.nic-vm.id]
  priority              = "Spot"
  eviction_policy       = "Delete"
  disk_controller_type  = "NVMe"

  os_disk {
    name                 = "os-disk-vm"
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [identity]
  }
}