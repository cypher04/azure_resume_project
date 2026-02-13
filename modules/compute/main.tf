
// Storage Account and Blob for VHD
resource "azurerm_storage_account" "sta" {
    name                     = "${var.project_name}${var.environment}sta"
    resource_group_name      = var.resource_group_name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    
}

data "azurerm_client_config" "current" {

}

resource "azurerm_storage_container" "stc" {
  
        name                  = "content"
        storage_account_name = azurerm_storage_account.sta.name
        container_access_type = "private"
}

// Static Website Hosting

resource "azurerm_storage_account_static_website" "sw" {
    storage_account_id = azurerm_storage_account.sta.id
    index_document     = "index.html"
    error_404_document = "404.html"
}

// CDN Resources


// Azure function to serve as backend for website (if needed)

resource "azurerm_storage_account" "func_sta" {
    name                     = "${var.project_name}${var.environment}funcsta"
    resource_group_name      = var.resource_group_name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    identity {
      type = "SystemAssigned"
    }
  
}

// App Service plan for function app
resource "azurerm_service_plan" "asp" {
    name                = "${var.project_name}-${var.environment}-asp"
    location            = var.location
    resource_group_name = var.resource_group_name
    os_type = "Linux"
    sku_name = "EP1"
}

// Function App

resource "azurerm_linux_function_app" "function" {
   name                = "${var.project_name}-${var.environment}-funcapp"
    location            = var.location
    resource_group_name = var.resource_group_name
    service_plan_id     = azurerm_service_plan.asp.id
    storage_account_name = azurerm_storage_account.func_sta.name
    storage_account_access_key = azurerm_storage_account.func_sta.primary_access_key
    public_network_access_enabled = false
    

    site_config {
        application_stack {
            python_version = "3.11"
        }
        cors {
                allowed_origins = ["https://portal.azure.com", "https://${azurerm_storage_account.sta.name}.z13.web.core.windows.net"]
            }
    }

    app_settings = {
        FUNCTIONS_WORKER_RUNTIME = "python"
        WEBSITE_RUN_FROM_PACKAGE = "1"
        cosmosdb_account_id      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmosdb_account_id.id})"
        cosmosdb_database_name   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmosdb_database_name.id})"
        cosmosdb_container_name  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmosdb_container_name.id})"
        cosmosdb_key             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmosdb_key.id})"
        cosmosdb_endpoint        = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmosdb_endpoint.id})"
    
        // add code to deploy app code package to function app


    }

    identity {
        type = "SystemAssigned"
    }

}

resource "azurerm_app_service_virtual_network_swift_connection" "funcapp_vnet_integration" {
    app_service_id =      azurerm_linux_function_app.function.id
    subnet_id           =  var.spoke_subnet_ids["function_subnet_id"]
    depends_on = [ azurerm_service_plan.asp ]
}

// connect function app to cosmosdb
# resource "azurerm_role_assignment" "func_cosmosdb" {
#     principal_id   = azurerm_linux_function_app.function.identity[0].principal_id
#     role_definition_name = "Cosmos DB Built-in Data Contributor"
#     scope          = var.cosmosdb_account_id
# }

// create GUID for function app to access cosmosdb
# resource "azurerm_role_definition" "func_cosmosdb_role" {
#     name        = "Cosmos DB Built-in Data Contributor"
#     scope       = var.cosmosdb_account_id
#     permissions {
#         actions = [
#             "Microsoft.DocumentDB/databaseAccounts/readMetadata",
#             "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
#             "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"   
#         ]
#     }
#     assignable_scopes = [var.cosmosdb_account_id]
  
# }

resource "azurerm_cosmosdb_sql_role_definition" "func_cosmosdb_role" {
    name        = "Cosmos DB Built-in Data Contributor"
    resource_group_name = var.resource_group_name
    account_name = var.cosmosdb_account_name
    assignable_scopes = [var.cosmosdb_account_id]
    permissions {
        data_actions = [
            "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read",
            "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/write",
            "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/delete"
        ]
    }
  
}

# resource "azurerm_role_assignment" "func_cosmosdb" {
#     principal_id   = azurerm_linux_function_app.function.identity[0].principal_id
#     role_definition_id = azurerm_role_definition.func_cosmosdb_role.id
#     scope          = var.cosmosdb_account_id
#     name = "00000000-0000-0000-0000-000000000002"
# }

resource "azurerm_cosmosdb_sql_role_assignment" "func_cosmosdb_assignment" {
    role_definition_id = azurerm_cosmosdb_sql_role_definition.func_cosmosdb_role.id
    principal_id       = azurerm_linux_function_app.function.identity[0].principal_id
    scope              = var.cosmosdb_account_id
    account_name = var.cosmosdb_account_name
    resource_group_name = var.resource_group_name
    name = "00000000-0000-0000-0000-000000000002"
  
}




// assign role for function app to access key vault secrets
resource "azurerm_role_assignment" "funcapp_kv_access" {
    scope                = azurerm_key_vault.kv.id
    role_definition_name = "Key Vault Secrets User"
    principal_id   = data.azurerm_client_config.current.object_id
}

// create a role assignment for the function app to access storage account
resource "azurerm_role_assignment" "funcapp_storageaccount" {
  scope                = azurerm_storage_account.func_sta.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id   = azurerm_linux_function_app.function.identity[0].principal_id
}


// create key vault and secrets for function app to access cosmosdb
resource "azurerm_key_vault" "kv" {
    name                = "${var.project_name}-${var.environment}-kv"
    location            = var.location
    resource_group_name = var.resource_group_name
    tenant_id           = data.azurerm_client_config.current.tenant_id
    enabled_for_disk_encryption = true
    soft_delete_retention_days = 7
    purge_protection_enabled = true
    sku_name            = "premium"


    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = data.azurerm_client_config.current.object_id

        secret_permissions = [
            "Get",
            "List",
            "Set"
        ]

        key_permissions = [
            "Get",
            "List"
        ]
    }
   
}


// create access policy for function app to access key vault secrets
# resource "azurerm_key_vault_access_policy" "funcapp_kv_access" {
#     key_vault_id = azurerm_key_vault.kv.id
#     tenant_id    = data.azurerm_client_config.current.tenant_id
#     object_id    = data.azurerm_client_config.current.object_id
#     secret_permissions = [
#         "Get",
#         "List",
#         "Set",
       
#     ]
#     key_permissions = [
#         "Get",
#         "List",

        
#     ]
# }


// access policy for user to access key vault secrets (for testing purposes)

# data "azuread_service_principal" "current" {
#     display_name = data.azurerm_client_config.current.client_id
# }

# resource "azurerm_key_vault_access_policy" "user_kv_access" {
#     key_vault_id = azurerm_key_vault.kv.id
#     tenant_id    = data.azurerm_client_config.current.tenant_id
#     object_id    = data.azuread_service_principal.current.object_id
#     secret_permissions = [
#         "Get",
#         "List",
#         "Set"
       
#     ]
#     key_permissions = [
#         "Get",
#         "List"
    
#     ]
# }

//
resource "azurerm_key_vault_secret" "cosmosdb_key" {
    name         = "CosmosDBKey"
    value        = var.cosmosdb_account_primary_key
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmosdb_account_id" {
    name         = "CosmosDBAccountId"
    value        = var.cosmosdb_account_id
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmosdb_endpoint" {
    name         = "CosmosDBEndpoint"
    value        = var.cosmosdb_account_endpoint
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmosdb_container_name" {
    name         = "CosmosDBContainerName"
    value        = var.cosmosdb_container_name
    key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "cosmosdb_database_name" {
    name         = "CosmosDBDatabaseName"
    value        = var.cosmosdb_database_name
    key_vault_id = azurerm_key_vault.kv.id
}



