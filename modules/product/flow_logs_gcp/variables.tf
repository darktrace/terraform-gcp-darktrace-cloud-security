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

variable "flow_logs_subscription" {
  type        = string
  description = "The path to a vpc flow logs pub / sub subscription. If this is not defined, then dt-managed infrastructure will be created"
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for the organisation sink."
  default     = ""
}
