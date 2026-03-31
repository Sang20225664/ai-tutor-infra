data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

module "acr" {
  source = "./modules/acr"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  acr_name_override   = var.acr_name_override
}

module "aks" {
  source = "./modules/aks"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  node_vm_size        = var.node_vm_size
  node_count          = var.node_count
  vnet_subnet_id      = module.networking.aks_subnet_id
  acr_id              = module.acr.acr_id

  depends_on = [module.networking, module.acr]
}

module "keyvault" {
  source = "./modules/keyvault"

  project_name             = var.project_name
  environment              = var.environment
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  current_user_oid         = data.azurerm_client_config.current.object_id
  aks_kv_identity_oid      = module.aks.key_vault_secrets_provider_object_id
  cosmos_connection_string = module.cosmosdb.connection_string
  jwt_secret               = var.jwt_secret
  gemini_api_key           = var.gemini_api_key

  depends_on = [module.aks, module.cosmosdb]
}

module "cosmosdb" {
  source = "./modules/cosmosdb"

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

module "github_oidc" {
  source = "./modules/github-oidc"

  project_name    = var.project_name
  github_username = var.github_username
  github_repo     = var.github_repo
  acr_id          = module.acr.acr_id
}

module "ingress" {
  source = "./modules/ingress"

  static_ip          = module.aks.ingress_static_ip
  letsencrypt_email  = var.letsencrypt_email
  letsencrypt_server = var.letsencrypt_server
  depends_on         = [module.aks]
}
