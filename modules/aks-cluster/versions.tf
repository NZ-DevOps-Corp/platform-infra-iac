# C:\Users\Admin\Documents\platform-infra-iac\modules\aks-cluster\versions.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Ensure compatibility with major version 3
    }
  }
  required_version = ">= 1.0"
}