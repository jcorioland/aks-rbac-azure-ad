provider "azurerm" {
    version = "~>1.19"
}

terraform {
    backend "azurerm" {}
}