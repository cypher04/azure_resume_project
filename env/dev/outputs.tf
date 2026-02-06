# output "storage_account_name" {
#   value = module.compute.storage_account_name
# }

# output "static_website_url" {
#     description = "The URL of the static website"
#     value       = module.compute.static_website_url
# }


# output "cosmosdb_account_endpoint" {
#     description = "The endpoint of the Cosmos DB account"
#     value       = module.database.cosmosdb_account_endpoint
# }

# output "cosmosdb_primary_key" {
#     description = "The primary key of the Cosmos DB account"
#     value       = module.database.cosmosdb_primary_key
# }

output "public_ip" {
    description = "The public IP address of the function app"
    value       = module.networking.public_ip
}

output "function_app_url" {
    description = "The URL of the function app"
    value       = module.compute.function_app_url
}


