# Terraform Azure Lab
# Created: December 03, 2019

# Build a resource group in Oregon
resource "azurerm_resource_group" "lab" {
    name                    = "lab"
    location                = "West US 2"
}

resource "azurerm_network_security_group" "lab" {
    name                    = "labSecurityGroupPublic"
    location                = azurerm_resource_group.lab.location
    resource_group_name     = azurerm_resource_group.lab.name
}

resource "azurerm_network_ddos_protection_plan" "lab" {
    name                    = "labDDOSPlan01"
    location                = azurerm_resource_group.lab.location
    resource_group_name     = azurerm_resource_group.lab.name
}

# Build a /24 lab network to play around with
resource "azurerm_virtual_network" "lab" {
    name                    = "lab-network"
    resource_group_name     = azurerm_resource_group.lab.name
    location                = azurerm_resource_group.lab.location
    address_space           = ["10.0.0.0/16"]

    ddos_protection_plan {
        id                      = azurerm_network_ddos_protection_plan.lab.id
        enable                  = true
    }

    subnet {
        name                    = "lab_public"
        address_prefix          = "10.0.2.0/24"
        security_group          = azurerm_network_security_group.lab.id
        # delegation {
        #     name                = "aciDelegation"
        #     service_delgation {
        #         name            = "Microsoft.ContainerInstance/containerGroups"
        #         ations          = ["Microsoft.Network/virtualNetworks/subnets/action"]
        #     }
        # }
    }

    subnet {
        name                    = "lab_private"
        address_prefix          = "10.0.1.0/24"
    }

    tags = {
        environment = "lab"
    }

}

# Deploy Azure Public IP for Load Balancer
resource "azurerm_public_ip" "lab" {
    name                    = "publicIPforLB"
    location                = azurerm_resource_group.lab.location
    resource_group_name     = azurerm_resource_group.lab.name
    allocation_method       = "Static"
}

# Deploy Azure Load Balancer
resource "azurerm_lb" "lab" {
    name                    = "LabLoadBalancer"
    location                = azurerm_resource_group.lab.location
    resource_group_name     = azurerm_resource_group.lab.name

    frontend_ip_configuration {
        name                = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.lab.id
        }
}

# Deploy Azure Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "lab" {
    name                    = "lab-aks1"
    location                = azurerm_resource_group.lab.location
    resource_group_name     = azurerm_resource_group.lab.name
    dns_prefix              = "labaks1"

    agent_pool_profile {
        name                = "default"
        enable_auto_scaling = true
        max_count           = 1
        min_count           = 1
        os_type             = "Linux"
        vm_size             = "Standard_B1ls"
    }

    service_principal {
        client_id           = "00000000-0000-0000-0000-000000000000"
        client_secret       = "00000000000000000000000000000000"
    }

    tags = {
        Environment         = "lab"
    }
}