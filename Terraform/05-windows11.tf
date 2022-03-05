# Network Interface
resource "azurerm_network_interface" "cloudlabs-vm-windows11-nic" {
  name                 = "CloudLabs-vm-windows11-nic"
  location             = data.azurerm_resource_group.cloudlabs-rg.location
  resource_group_name  = data.azurerm_resource_group.cloudlabs-rg.name

  ip_configuration {
    name                          = "CloudLabs-vm-windows11-config"
    subnet_id                     = azurerm_subnet.cloudlabs-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.13.37.150"
  }
}

resource "azurerm_network_interface_nat_rule_association" "cloudlabs-vm-windows11-nic-nat" {
  network_interface_id  = azurerm_network_interface.cloudlabs-vm-windows11-nic.id
  ip_configuration_name = "CloudLabs-vm-windows11-config"
  nat_rule_id           = azurerm_lb_nat_rule.cloudlabs-lb-nat-rdp.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "cloudlabs-vm-windows11" {
  name                = "CloudLabs-vm-windows11"
  computer_name       = "windows11"
  resource_group_name = data.azurerm_resource_group.cloudlabs-rg.name
  location            = data.azurerm_resource_group.cloudlabs-rg.location
  size                = "Standard_B4ms"
  provision_vm_agent  = true
  enable_automatic_updates = true
  admin_username      = var.windows-user
  admin_password      = random_string.adminpass.result
  network_interface_ids = [
    azurerm_network_interface.cloudlabs-vm-windows11-nic.id,
  ]

  os_disk {
    name                 = "CloudLabs-vm-windows11-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows11preview"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }

  additional_unattend_content {
    setting = "AutoLogon"
    content = "<AutoLogon><Password><Value>${random_string.adminpass.result}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.windows-user}</Username></AutoLogon>"
  }

  additional_unattend_content {
    setting = "FirstLogonCommands"
    content = "${file("${path.module}/files/FirstLogonCommands.xml")}"
  }
}