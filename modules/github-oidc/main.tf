data "azurerm_subscription" "current" {}

resource "azuread_application" "github_actions" {
  display_name = "${var.project_name}-github-actions"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-main"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_username}/${var.github_repo}:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}

resource "azuread_application_federated_identity_credential" "dev_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-dev"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_username}/${var.github_repo}:ref:refs/heads/dev"
  audiences      = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions.object_id
}
