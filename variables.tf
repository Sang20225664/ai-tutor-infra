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
  default     = "Standard_D2pls_v5"
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}

variable "acr_name_override" {
  description = "Override ACR if name is globally taken"
  type        = string
  default     = ""
}

variable "github_username" {
  description = "GitHub username or organization"
  type        = string
  default     = "Sang20225664"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "AI-Tutor"
}

variable "jwt_secret" {
  description = "JWT signing secret for auth service"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key for AI services"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt ACME registration"
  type        = string
}

variable "letsencrypt_server" {
  description = "ACME server URL for cert-manager"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}
