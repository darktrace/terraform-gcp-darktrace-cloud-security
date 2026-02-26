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

variable "logging_sink_filter" {
  type        = string
  description = "The filter defining which logs will be captured by the logging sink"
  default     = "logName:\"logs/networkmanagement.googleapis.com%2Fvpc_flows\" AND NOT jsonPayload.src_google_service.type=\"GOOGLE_API\" AND NOT jsonPayload.dest_google_service.type=\"GOOGLE_API\""
}
