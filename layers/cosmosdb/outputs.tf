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
