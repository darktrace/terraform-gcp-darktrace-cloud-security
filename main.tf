provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  wif_principal      = module.wif_principal_formatter.principal
  formatted_products = [for product in var.products : replace(product, "-", "_")]
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
  project_number = var.project_number
}


## **PRODUCT CONFIGURATION**

module "cloud_security_gcp" {
  count           = contains(local.formatted_products, "cloud_security_gcp") ? 1 : 0
  source          = "./modules/product/cloud_security_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
}

module "flow_logs_gcp" {
  count           = contains(local.formatted_products, "flow_logs_gcp") ? 1 : 0
  source          = "./modules/product/flow_logs_gcp"
  organisation_id = var.organisation_id
  principal       = local.wif_principal
  project_id      = var.project_id
}
