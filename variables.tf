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
  description = "The Customer ID of the Customer we are authenticating with"
}

variable "products" {
  type        = list(string)
  description = "Enabled products, subsequent auths with fewer products will destroy old deployments"
}
