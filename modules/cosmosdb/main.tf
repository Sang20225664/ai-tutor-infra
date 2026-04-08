resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-${var.environment}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"
  tags                = var.tags

  free_tier_enabled = true # $0/month — 1000 RU/s + 25GB free (1 free tier per subscription)

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  backup {
    type = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
  }
}

resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = "ai_tutor"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name

  throughput = 400
}
