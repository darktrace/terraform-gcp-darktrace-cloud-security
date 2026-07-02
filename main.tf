provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  wif_principal = module.wif_principal_formatter.principal
  # Add the target project to allowed_projects only if allowed_projects is defined
  allowed_projects  = length(var.allowed_projects) > 0 ? concat(tolist(var.allowed_projects), [var.project_id]) : var.allowed_projects
  scoped_deployment = length(var.allowed_projects) != 0
  project_number    = data.google_project.target_project.number
  # The organisation is typically the top-most ancestor
  organisation = data.google_project_ancestry.target_project_ancestry.ancestors[
    length(data.google_project_ancestry.target_project_ancestry.ancestors) - 1
  ]
  organisation_id = local.organisation.id
}

check "organisation_check" {
  # Fault tolerance, if we lack permissions we don't want to send bad data to the backend
  # If the organization ID is undefined or incorrect we may end up with global bucket collision
  assert {
    condition     = local.organisation.type == "organization"
    error_message = "Failed to retrieve organisation id. Principal authorisation is insufficient or blocked by a deny policy"
  }
}

data "google_project" "target_project" {
  project_id = var.project_id
}

data "google_project_ancestry" "target_project_ancestry" {
  project = var.project_id
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
  project_number = local.project_number
}

## **PRODUCT CONFIGURATION**

module "cloud_security_gcp" {
  count                         = contains(var.products, "cloud-security-gcp") ? 1 : 0
  source                        = "./modules/product/cloud_security_gcp"
  organisation_id               = local.organisation_id
  principal                     = local.wif_principal
  project_id                    = var.project_id
  custom_prefix                 = var.custom_prefix
  allowed_projects              = local.allowed_projects
  create_core_bucket            = var.create_core_bucket
  enable_core_bucket_versioning = var.enable_core_bucket_versioning
}

module "flow_logs_gcp" {
  count                  = contains(var.products, "flow-logs-gcp") ? 1 : 0
  source                 = "./modules/product/flow_logs_gcp"
  organisation_id        = local.organisation_id
  principal              = local.wif_principal
  project_id             = var.project_id
  flow_logs_subscription = var.flow_logs_subscription
  custom_prefix          = var.custom_prefix
  logging_sink_filter    = var.logging_sink_filter
  allowed_projects       = local.allowed_projects
}

module "cloud_respond_gcp" {
  count            = contains(var.products, "cloud-respond-gcp") ? 1 : 0
  source           = "./modules/product/cloud_respond_gcp"
  organisation_id  = local.organisation_id
  principal        = local.wif_principal
  project_id       = var.project_id
  custom_prefix    = var.custom_prefix
  allowed_projects = local.allowed_projects
}

module "audit_logs_gcp" {
  count            = contains(var.products, "audit-logs-gcp") ? 1 : 0
  source           = "./modules/product/audit_logs_gcp"
  organisation_id  = local.organisation_id
  principal        = local.wif_principal
  project_id       = var.project_id
  use_pubsub       = var.audit_logs_use_pubsub
  custom_prefix    = var.custom_prefix
  allowed_projects = local.allowed_projects
}

module "fai_gcp" {
  count           = contains(var.products, "cado-gcp") ? 1 : 0
  source          = "./modules/product/fai_gcp"
  organisation_id = local.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
  project_number  = local.project_number
  custom_prefix   = var.custom_prefix
  fai_gcs_bucket  = var.fai_gcs_bucket
}
