variable "organisation_id" {
  type        = string
  description = "The organisation in which the target project resides"
}
variable "project_id" {
  type        = string
  description = "Target install project ID"
}

variable "project_number" {
  type        = string
  description = "Target install Project number"
}

variable "region" {
  type        = string
  description = "Primary deployment region"
}

variable "aws_account_id" {
  type        = string
  description = "aws account id that contains the gcp auth role"
}

variable "customer_id" {
  type        = string
  description = "The Customer's Customer ID, used in conjunction with the deployment id to format the WIF principal"
}

variable "deployment_id" {
  type        = string
  description = "The customer's deployment ID, used in the principal for Workload Identity Federation"
}

variable "products" {
  type        = list(string)
  description = "Enabled products, subsequent auths with fewer products will destroy old deployments"
}

variable "flow_logs_subscription" {
  type        = string
  description = "The path to a vpc flow logs pub / sub subscription. If this is not defined, then dt-managed infrastructure will be created"
  default     = ""
}

variable "custom_prefix" {
  type        = string
  description = "A custom prefix for resources that must be globally unique by name. Used in testing for multiple deployments per organisation"
  default     = ""
}

variable "fai_gcs_bucket" {
  type        = string
  description = "The location of a GCS bucket for /Forensic Acquisition & Investigation. If not supplied a bucket will be created."
  default     = ""
}

variable "audit_logs_use_pubsub" {
  type        = bool
  description = "Create pubsub logging infrastructure for audit logs"
  default     = true
}
