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
  description = "The Customer's Customer ID, used in conjunction with the deployment id to format the WIF principal"
}

variable "deployment_id" {
  type        = string
  description = "The customer's deployment ID, used in the principal for Workload Identity Federation"
}

variable "project_number" {
  type        = string
  description = "Target install Project number"
}
