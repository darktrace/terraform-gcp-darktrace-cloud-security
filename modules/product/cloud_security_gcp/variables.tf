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

variable "allowed_projects" {
  type        = set(string)
  description = "The set of allowed projects for scoped deployment, if null then scoped deployment is not used"
  default     = []
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for resources that must be globally unique by name. Used in testing for multiple deployments per organisation"
}

variable "bucket_location" {
  type        = string
  description = "The GCS Bucket creation location"
}

variable "create_core_bucket" {
  type        = bool
  description = "Create the core enumeration bucket for resource exports"
  default     = false
}

variable "enable_core_bucket_versioning" {
  type        = bool
  description = "Enable versioning on the core bucket. Disabling will disable soft-deletion, allowing for easier tests"
  default     = true
}
