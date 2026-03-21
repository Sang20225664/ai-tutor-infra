variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "github_username" {
  description = "GitHub username or org"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "acr_id" {
  description = "ID of the ACR for AcrPush role"
  type        = string
}
