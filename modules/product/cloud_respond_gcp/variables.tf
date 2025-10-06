variable "organisation_id" {
  type        = string
  description = "The Organisation in which the project resides"
}

variable "project_id" {
  type        = string
  description = "Target install project ID"
}

variable "principal" {
  type        = string
  description = "The valid principal that the service account can be impersonated by"
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for resources that must be globally unique by name. Used in testing for multiple deployments per organisation"
}
