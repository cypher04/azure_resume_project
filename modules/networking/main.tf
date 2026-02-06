// hub and spoke netweork architecture

resource "azurerm_virtual_network" "hub_vnet" {
    name                = "${var.project_name}-${var.environment}-hub-vnet"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group_name

}

resource "azurerm_subnet" "hub-subnet" {
    name                 = "hub-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.hub_vnet.name
    address_prefixes     = [var.subnet_prefixes["database"]]  
}

resource "azurerm_virtual_network" "spoke_vnet" {
    name                = "${var.project_name}-${var.environment}-spoke-vnet"
    address_space       = var.spoke_address_space
    location            = var.location
    resource_group_name = var.resource_group_name
     
}


resource "azurerm_subnet" "spoke-subnet" {
    name                 = "spoke-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    address_prefixes     = [var.spoke_subnet_prefixes["web"]]  
}


resource "azurerm_subnet" "spoke-subnet-2" {
    name                 = "spoke-subnet-2"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    address_prefixes     = [var.spoke_subnet_prefixes["app"]]  
}


resource "azurerm_subnet" "spoke-subnet-3" {
    name                 = "spoke-subnet-3"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.spoke_vnet.name
    address_prefixes     = [var.spoke_subnet_prefixes["function"]]  
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
    name                      = "hub-to-spoke-peering"
    resource_group_name       = var.resource_group_name
    virtual_network_name      = azurerm_virtual_network.hub_vnet.name
    remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
    allow_forwarded_traffic   = true
    allow_gateway_transit     = false
    use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
    name                      = "spoke-to-hub-peering"
    resource_group_name       = var.resource_group_name
    virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
    remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
    allow_forwarded_traffic   = true
    allow_gateway_transit     = false
    use_remote_gateways       = false
}

resource "azurerm_public_ip" "pip" {
    name                = "${var.project_name}-${var.environment}-pip"
    location            = var.location
    resource_group_name = var.resource_group_name
    allocation_method   = "Static"
    sku                 = "Standard"
  
}





