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

variable "node_vm_size" {
  description = "VM size for AKS worker nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}
