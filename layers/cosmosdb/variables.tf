variable "project_name" {
  description = "Name of the project, used as prefix for all resources"
  type        = string
  default     = "ai-tutor"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "japaneast"
}

variable "resource_group_name" {
  description = "Name of the existing resource group (managed by root layer)"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the existing Key Vault to write MONGO-URI secret into"
  type        = string
}
