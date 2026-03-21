output "client_id" {
  description = "Client ID for AZURE_CLIENT_ID GitHub Secret"
  value       = azuread_application.github_actions.client_id
}

output "app_display_name" {
  description = "Display name of the App Registration"
  value       = azuread_application.github_actions.display_name
}
