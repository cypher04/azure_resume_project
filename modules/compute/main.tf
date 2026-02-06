
// Storage Account and Blob for VHD
resource "azurerm_storage_account" "sta" {
    name                     = "${var.project_name}${var.environment}sta"
    resource_group_name      = var.resource_group_name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    
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
    sku_name = "Y1"
}

// Function App

resource "azurerm_linux_function_app" "function" {
   name                = "${var.project_name}-${var.environment}-funcapp"
    location            = var.location
    resource_group_name = var.resource_group_name
    service_plan_id     = azurerm_service_plan.asp.id
    storage_account_name = azurerm_storage_account.func_sta.name
    storage_account_access_key = azurerm_storage_account.func_sta.primary_access_key

    site_config {
        application_stack {
            python_version = "3.8"
        }
        cors {
                allowed_origins = ["https://portal.azure.com", "https://${azurerm_storage_account.sta.name}.z13.web.core.windows.net"]
            }
    }

    app_settings = {
        FUNCTIONS_WORKER_RUNTIME = "python"
        WEBSITE_RUN_FROM_PACKAGE = "1"
        COSMOSDB_ACCOUNT_ID      = var.cosmosdb_account_id
        cosmosdb_database_name   = var.cosmosdb_database_name
        cosmosdb_container_name  = var.cosmosdb_container_name
        cosmosdb_key             = var.cosmosdb_account_primary_key
        cosmosdb_endpoint        = var.cosmosdb_account_endpoint
        // add code to deploy app code package to function app


    }

    identity {
        type = "SystemAssigned"
    }

}

// connect function app to cosmosdb
resource "azurerm_role_assignment" "func_cosmosdb" {
    principal_id   = azurerm_linux_function_app.function.identity[0].principal_id
    role_definition_name = "Cosmos DB Account Reader Role"
    scope          = var.cosmosdb_account_id
}

// create a role assignment for the function app to access storage account
resource "azurerm_role_assignment" "funcapp_storageaccount" {
  scope                = azurerm_storage_account.func_sta.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id   = azurerm_linux_function_app.function.identity[0].principal_id
}

