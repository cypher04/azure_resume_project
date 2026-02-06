// backend configuration for Terraform state
terraform {
  backend "azurerm" {
    resource_group_name  = "myprojectdev-rg-new"
    storage_account_name = "myprojectstatedevresume"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}