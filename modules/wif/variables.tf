variable "project_id" {
  type        = string
  description = "Target install project ID"
}

variable "region" {
  type        = string
  description = "Primary deployment region"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID that contains the GCP auth role"
}
