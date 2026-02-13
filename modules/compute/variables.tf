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

# variable "storage_account_name" {
#   description = "The name of the storage account"
#   type        = string
# }

variable "storage_account_for_funcapp" {
  description = "The name of the storage account for the function app"
  type        = string
}

variable "cosmosdb_account_id" {
  description = "The ID of the Cosmos DB account"
  type        = string
}

variable "cosmosdb_container_name" {
  description = "The name of the Cosmos DB container"
  type        = string
}

variable "cosmosdb_database_name" {
  description = "The name of the Cosmos DB database"
  type        = string
}

variable "cosmosdb_account_primary_key" {
  description = "The primary key of the Cosmos DB account"
  type        = string
}

variable "cosmosdb_account_endpoint" {
  description = "The endpoint of the Cosmos DB account"
  type        = string
}


variable "spoke_subnet_ids" {
  description = "The IDs of the spoke subnets for virtual network integration"
  type        = map(string)
}

variable "cosmosdb_account_name" {
  description = "The name of the Cosmos DB account"
  type        = string
}
