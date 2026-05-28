variable "organisation_id" {
  type        = string
  description = "The Organisation in which the project resides"
}

variable "project_id" {
  type        = string
  description = "Target install project ID"
}

variable "allowed_projects" {
  type        = set(string)
  description = "The set of allowed projects for scoped deployment, if null then scoped deployment is not used"
  default     = []
}

variable "principal" {
  type        = string
  description = "The valid principal that the service account can be impersonated by"
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for resources that must be globally unique by name. Used in testing for multiple deployments per organisation"
}
