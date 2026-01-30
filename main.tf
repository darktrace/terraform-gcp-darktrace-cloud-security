provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  wif_principal = module.wif_principal_formatter.principal
}

module "wif" {
  source         = "./modules/wif"
  project_id     = var.project_id
  aws_account_id = var.aws_account_id
  region         = var.region
}

module "wif_principal_formatter" {
  source         = "./modules/wif_principal_formatter"
  wip_name       = module.wif.wip_name
  aws_account_id = var.aws_account_id
  customer_id    = var.customer_id
  deployment_id  = var.deployment_id
  project_number = var.project_number
}


## **PRODUCT CONFIGURATION**

module "cloud_security_gcp" {
  count           = contains(var.products, "cloud-security-gcp") ? 1 : 0
  source          = "./modules/product/cloud_security_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
}

module "flow_logs_gcp" {
  count                  = contains(var.products, "flow-logs-gcp") ? 1 : 0
  source                 = "./modules/product/flow_logs_gcp"
  organisation_id        = var.organisation_id
  principal              = local.wif_principal
  project_id             = var.project_id
  flow_logs_subscription = var.flow_logs_subscription
  custom_prefix          = var.custom_prefix
}

module "cloud_respond_gcp" {
  count           = contains(var.products, "cloud-respond-gcp") ? 1 : 0
  source          = "./modules/product/cloud_respond_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
  custom_prefix   = var.custom_prefix
}

module "audit_logs_gcp" {
  count           = contains(var.products, "audit-logs-gcp") ? 1 : 0
  source          = "./modules/product/audit_logs_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
  use_pubsub      = var.audit_logs_use_pubsub
  custom_prefix   = var.custom_prefix
}

module "fai_gcp" {
  count           = contains(var.products, "cado-gcp") ? 1 : 0
  source          = "./modules/product/fai_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
  project_number  = var.project_number
  custom_prefix   = var.custom_prefix
  fai_gcs_bucket  = var.fai_gcs_bucket
}
