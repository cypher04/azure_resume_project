variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
}

# variable "cosmosdb_database_name" {
#   description = "The name of the Cosmos DB database"
#   type        = string
# }

# variable "cosmosdb_container_name" {
#   description = "The name of the Cosmos DB container"
#   type        = string
# }


