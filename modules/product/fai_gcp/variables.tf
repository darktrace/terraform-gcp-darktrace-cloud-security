variable "organisation_id" {
  type        = string
  description = "The Organisation in which the project resides"
}

variable "project_id" {
  type        = string
  description = "Target install project ID"
}

variable "project_number" {
  type        = string
  description = "Target install project number"
}

variable "principal" {
  type        = string
  description = "The valid principal that the service account can be impersonated by"
}

variable "fai_gcs_bucket" {
  type        = string
  description = "The location of a GCS bucket, must be in the same project. If not supplied a bucket will be created."
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for the organisation sink."
  default     = ""
}
