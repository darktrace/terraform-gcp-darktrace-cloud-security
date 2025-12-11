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

variable "use_pubsub" {
  type        = bool
  description = "Create a pubsub based stack for log collection"
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for the organisation sink."
  default     = ""
}
