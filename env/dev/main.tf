resource "azurerm_resource_group" "rg-mainn" {
  name     = "rg-${var.project_name}-${var.environment}-new"
  location = var.location
  
 
}


data "azurerm_client_config" "current" {
}

module "compute" {
  source              = "../../modules/compute"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name      = azurerm_resource_group.rg-mainn.name
  storage_account_for_funcapp = module.compute.storage_account_for_funcapp
  cosmosdb_account_id = module.database.cosmosdb_account_id
  cosmosdb_account_primary_key = module.database.cosmosdb_account_primary_key
  cosmosdb_account_endpoint = module.database.cosmosdb_account_endpoint
  cosmosdb_database_name = module.database.cosmosdb_database_name
  cosmosdb_container_name = module.database.cosmosdb_container_name

  depends_on = [ module.database ]
}

module "database" {
  source              = "../../modules/database"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-mainn.name
  # cosmosdb_container_name = module.database.cosmosdb_container_name
  # cosmosdb_database_name = module.database.cosmosdb_database_name
  
}


module "networking" {
  source              = "../../modules/networking"
  project_name        = var.project_name
  resource_group_name = var.resource_group_name
  environment         = var.environment
  location            = var.location
  subnet_prefixes     = var.subnet_prefixes
  address_space       = var.address_space
  spoke_address_space = var.spoke_address_space
  spoke_subnet_prefixes = var.spoke_subnet_prefixes
}



# // Create Private DNS Zone for App Service
# resource "azurerm_private_dns_zone" "pdz" {
#     name                = "privatelink.azurewebsites.net"
#     resource_group_name = var.resource_group_name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "pdz_vnet_link" {
#     name                  = "${var.project_name}-pdz-vnet-link-${var.environment}"
#     resource_group_name   = var.resource_group_name
#     private_dns_zone_name = azurerm_private_dns_zone.pdz.name
#     virtual_network_id    = module.networking.spoke_vnet_id
#     registration_enabled  = false
# }


# // Create Private Endpoint for App Service in Spoke VNet for inbound traffic
# resource "azurerm_private_endpoint" "pe-appservice" {
#   name                = "${var.project_name}-pe-appservice-${var.environment}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = module.networking.spoke_subnet_ids.function_subnet_id

#   private_service_connection {
#     name                           = "${var.project_name}-psc-appservice-${var.environment}"
#     private_connection_resource_id = module.compute.linux_function_app_id
#     is_manual_connection           = false
#     subresource_names              = ["sites"]
#   }

#   private_dns_zone_group {
#       name                 = "app-dns-zone-group"
#       private_dns_zone_ids = [azurerm_private_dns_zone.pdz.id]
#   }
# }


// Create Private Endpoint for Cosmos DB in Spoke 1 VNet for inbound traffic
resource "azurerm_private_endpoint" "pe-cosmosdb" {
  name                = "${var.project_name}-pe-cosmosdb-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
subnet_id           = module.networking.hub_subnet_ids.hub_subnet_id
  private_service_connection {
    name                           = "${var.project_name}-psc-cosmosdb-${var.environment}"
    private_connection_resource_id = module.database.cosmosdb_account_id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }
  private_dns_zone_group {
      name                 = "cosmosdb-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_pdz.id]
  }
} 

// create dns zone for cosmos db
resource "azurerm_private_dns_zone" "cosmosdb_pdz" {
    name                = "privatelink.documents.azure.com"
    resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb_pdz_vnet_link" {
    name                  = "${var.project_name}-cosmosdb-pdz-vnet-link-${var.environment}"
    resource_group_name   = var.resource_group_name
    private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_pdz.name
    virtual_network_id    = module.networking.hub_vnet_id
    registration_enabled  = false
} 







