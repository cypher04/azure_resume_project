resource "azurerm_cosmosdb_account" "cosmosdb" {
    name                = "${var.project_name}-${var.environment}-cosmosdb"
    location            = var.location
    resource_group_name = var.resource_group_name
    offer_type          = "Standard"
    kind                = "GlobalDocumentDB"
    consistency_policy {
        consistency_level       = "Session"
    }

    capabilities {
        name = "EnableServerless"
    }
    geo_location {
        location          = var.location
        failover_priority = 0
    }
  
}

resource "azurerm_cosmosdb_sql_database" "sqldb" {
    name                = "${var.project_name}-${var.environment}-sqldb"
    resource_group_name = var.resource_group_name
    account_name       = azurerm_cosmosdb_account.cosmosdb.name
}

resource "azurerm_cosmosdb_sql_container" "sqlcnt" {
    name                = "${var.project_name}-${var.environment}-sqlcnt"
    resource_group_name = var.resource_group_name
    account_name       = azurerm_cosmosdb_account.cosmosdb.name
    database_name      = azurerm_cosmosdb_sql_database.sqldb.name
    partition_key_paths = ["/userId"]
}




