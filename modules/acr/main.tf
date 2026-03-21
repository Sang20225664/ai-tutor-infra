locals {
  acr_name = var.acr_name_override != "" ? var.acr_name_override : "${replace(var.project_name, "-", "")}${var.environment}acr"
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
