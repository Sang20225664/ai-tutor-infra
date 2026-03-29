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

  project_name        = var.project_name
  environment         = var.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  current_user_oid    = data.azurerm_client_config.current.object_id
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
  depends_on = [module.aks]
}
