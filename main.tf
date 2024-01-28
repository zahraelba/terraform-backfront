provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Resource_gr_backfront_z" {
  name     = "Resource_gr_backfront_z"
  location = "France central"
}

resource "azurerm_virtual_network" "Vnet_backfront_z" {
  name                = "Vnet_backfront_z"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Resource_gr_backfront_z.location
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name
}

resource "azurerm_subnet" "Subnet_backfront_z" {
  name                 = "Subnet_backfront_z"
  resource_group_name  = azurerm_resource_group.Resource_gr_backfront_z.name
  virtual_network_name = azurerm_virtual_network.Vnet_backfront_z.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "Public_ip_backfront_z" {
  name                = "Public_ip_backfront_z"
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name
  location            = azurerm_resource_group.Resource_gr_backfront_z.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "NSG_backfront_z" {
  name                = "NSG_backfront_z"
  location            = azurerm_resource_group.Resource_gr_backfront_z.location
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "Nic_backfront_z" {
  name                = "Nic_backfront_z"
  location            = azurerm_resource_group.Resource_gr_backfront_z.location
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name

  ip_configuration {
    name                          = "NicConfig_backfront_z"
    subnet_id                     = azurerm_subnet.Subnet_backfront_z.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Public_ip_backfront_z.id
  }
}

resource "tls_private_key" "generated_key1" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}
resource "local_file" "private_key" {
  content  = tls_private_key.generated_key1.private_key_pem
  filename = "${path.module}/backfront_z_private_key.pem"
}

#output "private_key_file" {
 # value = file.private_key.filename
#}

resource "azurerm_linux_virtual_machine" "backfront_zahra" {
  name                  = "backfront_zahra"
  location              = azurerm_resource_group.Resource_gr_backfront_z.location
  resource_group_name   = azurerm_resource_group.Resource_gr_backfront_z.name
  network_interface_ids = [azurerm_network_interface.Nic_backfront_z.id]
  size                  = "Standard_DS1_v2"

  admin_username = "zahra"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "zahra"
    public_key = tls_private_key.generated_key1.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "backfrontzahra"

}

# Création du serveur PostgreSQL
resource "azurerm_postgresql_server" "postgresql_server" {
  name                = "postgres-server"
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name
  location            = azurerm_resource_group.Resource_gr_backfront_z.location
  sku_name            = "B_Gen5_1"
  version             = "11"
  administrator_login          = "postgresadmin"
  administrator_login_password = "zahra96ZAHRA"

  ssl_enforcement_enabled = true
  create_mode          = "Default"

}

# Création de la base de données PostgreSQL
resource "azurerm_postgresql_database" "postgresql_database" {
  name                = "omega"
  resource_group_name = azurerm_resource_group.Resource_gr_backfront_z.name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  charset             = "UTF8"
  collation           = "French_France.1252"
}

output "private_key" {
  value = tls_private_key.generated_key1.private_key_pem
  sensitive = true
}


