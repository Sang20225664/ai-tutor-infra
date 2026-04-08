# Reference the existing Resource Group managed by the root layer
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Reference the existing Key Vault managed by the root layer
data "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.main.name
}

module "cosmosdb" {
  source = "../../modules/cosmosdb"

  project_name        = var.project_name
  environment         = var.environment
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Layer       = "cosmosdb"
  }
}

# Write MONGO-URI into Key Vault so the app can connect to CosmosDB
# When this layer is destroyed, the secret is also removed (expected behavior — app loses DB connectivity)
resource "azurerm_key_vault_secret" "mongo_uri" {
  name         = "MONGO-URI"
  value        = module.cosmosdb.connection_string
  key_vault_id = data.azurerm_key_vault.main.id
}
