terraform {
  required_version = ">= 1.3.0"

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0"
    }
  }
}
