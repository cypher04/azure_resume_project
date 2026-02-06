output "public_ip_id" {
    description = "The ID of the public IP"
    value       = azurerm_public_ip.pip.id
}

output "hub_vnet_id" {
    description = "The ID of the hub virtual network"
    value       = azurerm_virtual_network.hub_vnet.id
}

output "spoke_vnet_id" {
    description = "The ID of the spoke virtual network"
    value       = azurerm_virtual_network.spoke_vnet.id
}

output "spoke_subnet_ids" {
    description = "The IDs of the spoke subnets"
    value = {
        web_subnet_id      = azurerm_subnet.spoke-subnet.id
        app_subnet_id      = azurerm_subnet.spoke-subnet-2.id
        function_subnet_id = azurerm_subnet.spoke-subnet-3.id
    }
}

output "hub_subnet_ids" {
    description = "The IDs of the hub subnets"
    value = {
        hub_subnet_id = azurerm_subnet.hub-subnet.id
    }
}

output "public_ip" {
    description = "The public IP address"
    value       = azurerm_public_ip.pip.ip_address
}
