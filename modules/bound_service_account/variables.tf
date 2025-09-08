variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account to create"
}

variable "service_account_display_name" {
  type        = string
  description = "The display name of the service account"
}

variable "principal" {
  type        = string
  description = "The principal that is allowed to impersonate the SA"
}
