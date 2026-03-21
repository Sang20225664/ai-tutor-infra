variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "node_vm_size" {
  description = "VM size for AKS worker nodes"
  type        = string
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
}

variable "vnet_subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

variable "acr_id" {
  description = "ID of the Azure Container Registry for AcrPull role assignment"
  type        = string
}
