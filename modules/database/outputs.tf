output "cosmosdb_account_id" {
    value = azurerm_cosmosdb_account.cosmosdb.id
}

output "cosmosdb_database_name" {
    value = azurerm_cosmosdb_sql_database.sqldb.name
}

output "cosmosdb_container_name" {
    value = azurerm_cosmosdb_sql_container.sqlcnt.name
}

output "cosmosdb_account_endpoint" {
    value = azurerm_cosmosdb_account.cosmosdb.endpoint
}

output "cosmosdb_account_primary_key" {
    value = azurerm_cosmosdb_account.cosmosdb.primary_key
    sensitive = true
}

output "cosmosdb_account_name" {
    value = azurerm_cosmosdb_account.cosmosdb.name
}

