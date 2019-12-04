# Terraform Azure Lab
# Created: December 03, 2019

# Build a resource group in Oregon
resource "azurerm_resource_group" "lab" {
    name                    = "lab"
    location                = "West US 2"
}

# Build a /24 lab network to play around with
resource "azurerm_virtual_network" "lab" {
    name                    = "lab-network"
    resource_group_name     = azurerm_resource_group.lab.name
    location                = azurerm_resource_group.location
    address_space           = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "lab_public" {
    name                    = "lab_public"
    resource_group_name     = azurerm_resource_group.lab.name
    virtual_network_name    = azurerm_virtual_network.lab.name
    address_prefix          = "10.0.2.0/24"
}


