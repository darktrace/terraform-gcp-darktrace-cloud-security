variable "wip_name" {
  description = "The Workload Identity Pool with which to register the Service Account"
  type        = string
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID that contains the GCP auth role"
}

variable "customer_id" {
  type        = string
  description = "The Customer ID of the Customer we are authenticating with"
}

variable "project_number" {
  type        = string
  description = "Target install Project number"
}
