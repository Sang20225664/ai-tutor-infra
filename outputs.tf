output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = module.acr.login_server
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = module.keyvault.vault_uri
}

output "kubeconfig_command" {
  description = "Azure CLI command to get kubeconfig for the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

output "cosmos_endpoint" {
  description = "Endpoint URL of the CosmosDB account"
  value       = module.cosmosdb.endpoint
}

output "cosmos_account_name" {
  description = "Name of the CosmosDB account"
  value       = module.cosmosdb.account_name
}

output "cosmos_connection_string" {
  description = "Primary connection string for CosmosDB"
  value       = module.cosmosdb.connection_string
  sensitive   = true
}

output "github_actions_client_id" {
  description = "Use for AZURE_CLIENT_ID in GitHub Secrets"
  value       = module.github_oidc.client_id
}
