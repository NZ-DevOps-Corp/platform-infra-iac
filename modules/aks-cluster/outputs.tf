# C:\Users\Admin\Documents\platform-infra-iac\modules\aks-cluster\outputs.tf

# 1. Raw Kubeconfig (required for the Kubernetes/Helm providers in the root module)
output "kube_config_raw" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  description = "The raw Kube Config file content for the AKS cluster."
  sensitive   = true # Mask this value in Terraform plan/output
}

# 2. Cluster Name
output "kubernetes_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "The name of the provisioned AKS cluster."
}

# 3. Resource Group Name
output "resource_group_name" {
  value       = azurerm_resource_group.project_rg.name
  description = "The name of the resource group where the cluster is deployed."
}

# 4. Managed Identity Principal ID (for granting permissions, e.g., ACR Pull)
output "kubelet_principal_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  description = "The Principal ID of the Kubelet Managed Identity."
}