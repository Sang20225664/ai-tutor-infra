output "connection_string" {
  description = "Primary connection string for CosmosDB"
  value       = azurerm_cosmosdb_account.main.connection_strings[0]
  sensitive   = true
}

output "endpoint" {
  description = "Endpoint URL of the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "account_name" {
  description = "Name of the CosmosDB account"
  value       = azurerm_cosmosdb_account.main.name
}
