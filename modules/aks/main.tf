resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"

  default_node_pool {
    name                        = "default"
    temporary_name_for_rotation = "temppool"
    node_count                  = var.node_count
    vm_size                     = var.node_vm_size
    max_pods                    = 110
    vnet_subnet_id              = var.vnet_subnet_id

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }

    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create a Static Public IP for the NGINX Ingress Controller in the Node Resource Group
resource "azurerm_public_ip" "ingress" {
  name                = "${var.project_name}-${var.environment}-ingress-ip"
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Grant AKS kubelet identity AcrPull role on ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
