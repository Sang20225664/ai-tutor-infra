resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "ai-tutor"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}

# Kept here as requested, but guarded to avoid dependency cycle with AKS creation.
resource "azurerm_monitor_metric_alert" "pod_restart" {
  count               = var.aks_id == null ? 0 : 1
  name                = "pod-restart-alert"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_id]
  description         = "Alert when pod count indicates potential instability"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "PodCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
