# C:\Users\Admin\Documents\platform-infra-iac\modules\aks-cluster\main.tf

# 1. Resource Group
resource "azurerm_resource_group" "project_rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 2. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location
  sku                 = "Premium" # Recommended SKU for Private Link and zone redundancy
  admin_enabled       = false     # Best practice: Use Managed Identity for ACR pull, not admin user
  tags                = var.tags
}

# 3. Azure Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 90 # Increased retention for compliance
  tags                = var.tags
}

# 4. Azure Kubernetes Service (AKS) - Hardened Configuration
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  dns_prefix          = "aks-${var.project_name}-${var.environment}"

  # --- SECURITY HARDENING ---
  
  # 1. Private Cluster (API Server isolation)
  private_cluster_enabled = true
  
  # 2. Azure AD (Entra ID) RBAC Integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.admin_group_object_id]
  }

  # 3. Azure Policy and Monitoring Add-ons
  addon_profile {
    azure_policy {
      enabled = true # Enables Azure Policy for Kubernetes (Gatekeeper)
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
    }
  }

  # 4. CNI Networking
  network_profile {
    network_plugin     = "azure" # Azure CNI for VNet integration
    network_policy     = "calico" # Recommended for network policy enforcement
    dns_service_ip     = "10.2.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  # 5. Default Node Pool Configuration
  default_node_pool {
    name                     = "systempool"
    node_count               = var.node_count
    vm_size                  = var.vm_size
    vnet_subnet_id           = var.vnet_subnet_id             # VNet Integration
    disk_encryption_set_id   = var.disk_encryption_set_id     # CMK Encryption
    host_encryption_enabled  = true                           # Encrypts OS and Temp disks
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# 5. Diagnostic Settings (Connects AKS Logs to Log Analytics Workspace)
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "aks-diag-${var.environment}"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id

  dynamic "enabled_log" {
    for_each = ["kube-audit", "kube-apiserver", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler"]
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}