# C:\Users\Admin\Documents\platform-infra-iac\modules\aks-cluster\variables.tf

variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
}

variable "project_name" {
  description = "A short name for the project, used to prefix resource names."
  type        = string
}

variable "environment" {
  description = "The name of the environment (e.g., 'dev', 'stage')."
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the default AKS system node pool."
  type        = number
}

variable "vm_size" {
  description = "The VM size for the AKS node pool."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
}

# --- Corporate Security/Networking Variables ---

variable "vnet_subnet_id" {
  description = "The Resource ID of the pre-existing VNet Subnet to deploy the AKS nodes into (required for Azure CNI)."
  type        = string
}

variable "admin_group_object_id" {
  description = "The Azure AD (Entra ID) Object ID of the group that should be granted cluster-admin access."
  type        = string
}

variable "disk_encryption_set_id" {
  description = "The Resource ID of the Customer Managed Key (CMK) Disk Encryption Set to use for encrypting node OS and Data disks."
  type        = string
}