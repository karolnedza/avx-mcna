### Azure Resource Group

resource "azurerm_resource_group" "avx-management" {
  name     = "avx-management"
  location = "West Europe"
}


#### VNet where Controller and Copilot will be deployed

resource "azurerm_virtual_network" "avx-management-vnet" {
  name                = "avx-management-vnet"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name
  address_space       = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "avx-management-vnet-subnet1" {
  name                 = "avx-management-vnet-subnet1"
  resource_group_name  = azurerm_resource_group.avx-management.name
  virtual_network_name = azurerm_virtual_network.avx-management-vnet.name
  address_prefixes       = ["10.10.0.0/25"]
}

resource "azurerm_subnet" "avx-management-vnet-subnet2" {
  name                 = "avx-management-vnet-subnet2"
  resource_group_name  = azurerm_resource_group.avx-management.name
  virtual_network_name = azurerm_virtual_network.avx-management-vnet.name
  address_prefixes       = ["10.10.0.128/25"]
}


####### Network Security Groups

resource "azurerm_network_security_group" "avx-controller-nsg" {
  name                = "avx-controller-nsg"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  security_rule {
    name                       = "https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description = "https-for-controller"
  }

#   security_rule {
#   name                       = "ssh"
#   priority                   = 200
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   destination_port_range     = "22"
#   source_address_prefix      = "*"
#   destination_address_prefix = "*"
#   description = "ssh-for-controller" # only when AVX Support asks !!
#
# }

  tags = {
    environment = "Production"
    terraform_created = "true"
  }

  lifecycle {
   ignore_changes = [security_rule]
 }
}


resource "azurerm_network_security_group" "avx-copilot-nsg" {
  name                = "avx-copilot-nsg"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  security_rule {
    name                       = "https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description = "https-for-copilot"
  }

  security_rule {
    name                       = "netflow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "udp"
    source_port_range          = "*"
    destination_port_range     = "31283"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description = "netflow-for-copilot"
  }

  security_rule {
    name                       = "syslog"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "udp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description = "syslog-for-copilot"
  }
#   security_rule {
#   name                       = "ssh"
#   priority                   = 400
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   destination_port_range     = "22"
#   source_address_prefix      = "*"
#   destination_address_prefix = "*"
#   description = "ssh-for-copilot" # only when AVX Support asks !!
#
# }

  tags = {
    environment = "Production"
    terraform_created = "true"
  }
}

##### Network Interface and a Network Security Group

# nsg attached to Controller
resource "azurerm_network_interface_security_group_association" "controller-iface-nsg" {
  network_interface_id      = azurerm_network_interface.avx-ctrl-iface.id
  network_security_group_id = azurerm_network_security_group.avx-controller-nsg.id
}

# nsg attached to Copilot
resource "azurerm_network_interface_security_group_association" "copilot-iface-nsg" {
  network_interface_id      = azurerm_network_interface.avx-copilot-iface.id
  network_security_group_id = azurerm_network_security_group.avx-copilot-nsg.id
}


####################### Aviatrix Controller

#### AVX Controller Public IP
resource "azurerm_public_ip" "avx-controller-public-ip" {
  name                    = "avx-controller-public-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

### AVX Controller Interface

resource "azurerm_network_interface" "avx-ctrl-iface" {
  name                = "avx-ctrl-nic"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  ip_configuration {
    name                          = "avx-controller-nic"
    subnet_id                     = azurerm_subnet.avx-management-vnet-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.avx-controller-public-ip.id
  }
}


### AVX Controller VM instance

resource "azurerm_virtual_machine" "avx-controller" {
  name                  = "AviatrixController"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-ctrl-iface.id]
  vm_size               = "Standard_D8s_v3"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-bundle-payg"
    sku       = "aviatrix-enterprise-bundle-byol"
    version   = "latest"
  }

  plan {
    name = "aviatrix-enterprise-bundle-byol"
    publisher = "aviatrix-systems"
    product = "aviatrix-bundle-payg"
  }

  storage_os_disk {
    name              = "avxdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "avx-controller"
    admin_username = "avxadmin" #Code Message="The Admin Username specified is not allowed."
    admin_password = "Avi@tr1xRocks!!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}





################# Aviatrix Copilot

#### AVX Copilot Public IP
resource "azurerm_public_ip" "avx-copilot-public-ip" {
  name                    = "avx-controller-copilot-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

### AVX Controller Interface

resource "azurerm_network_interface" "avx-copilot-iface" {
  name                = "avx-copilot-nic"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  ip_configuration {
    name                          = "avx-copilot-nic"
    subnet_id                     = azurerm_subnet.avx-management-vnet-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.avx-copilot-public-ip.id
  }
}


### AVX Controller VM instance

resource "azurerm_virtual_machine" "avx-copilot" {
  name                  = "AviatrixCopilot"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-copilot-iface.id]
  vm_size               = "Standard_D8s_v3"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-copilot"
    sku       = "avx-cplt-byol-01"
    version   = "latest"
  }

  plan {
    name = "avx-cplt-byol-01"
    publisher = "aviatrix-systems"
    product = "aviatrix-copilot"
  }

  storage_os_disk {
    name              = "avxcpltdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "avx-copilot "
    admin_username = "avxadmin" #Code Message="The Admin Username specified is not allowed."
    admin_password = "Avi@tr1xRocks!!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
