locals {
  sa_name         = "darktrace-audit-logs"
  sa_display_name = "Darktrace /CLOUD Audit Logs"
  sa_email        = module.bound_service_account.sa_email
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

## The following Role Assignments are suggested in the GCP Deployment Guide
## https://customerportal.darktrace.com/product-guides/main/gcp-deploy-standalone

resource "google_organization_iam_member" "sa_org_viewer" {
  org_id = var.organisation_id
  role   = "roles/resourcemanager.organizationViewer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "sa_org_priv_logs" {
  org_id = var.organisation_id
  role   = "roles/logging.privateLogViewer"
  member = "serviceAccount:${local.sa_email}"
}
