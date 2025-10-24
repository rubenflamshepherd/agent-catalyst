// ABOUTME: Defines input variables for the Terraform configuration.
// ABOUTME: Includes project ID, app name, and GitHub repository settings.

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository"
  type        = string

  validation {
    condition     = length(trimspace(var.github_owner)) > 0
    error_message = "github_owner must be a non-empty string."
  }
}

variable "github_repo" {
  description = "GitHub repository name connected to Cloud Build"
  type        = string

  validation {
    condition     = length(trimspace(var.github_repo)) > 0
    error_message = "github_repo must be a non-empty string."
  }
}
