output "storage_account_id" {
    description = "The ID of the storage account"
    value       = azurerm_storage_account.sta.id
}

output "storage_account_id_for_funcapp" {
    description = "The ID of the storage account for the function app"
    value       = azurerm_storage_account.func_sta.id
}

output "static_website_url" {
    description = "The URL of the static website"
    value       = azurerm_storage_account.sta.primary_web_endpoint
}

output "storage_account_for_funcapp" {
    description = "The name of the storage account for the function app"
    value       = azurerm_storage_account.func_sta.name
}

output "storage_account_name" {
    description = "The name of the storage account"
    value       = azurerm_storage_account.sta.name
}

output "linux_function_app_id" {
    description = "The ID of the Linux Function App"
    value       = azurerm_linux_function_app.function.id
}

output "function_app_url" {
    description = "The URL of the Function App"
    value       = azurerm_linux_function_app.function.default_hostname
}