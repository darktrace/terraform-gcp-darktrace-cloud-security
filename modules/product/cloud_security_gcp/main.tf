locals {
  sa_name         = "darktrace-core-service-account"
  sa_display_name = "Darktrace /CLOUD Enumeration"
  sa_email        = module.bound_service_account.sa_email
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

resource "google_organization_iam_member" "sa_org_service_usage_consumer" {
  org_id = var.organisation_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "sa_org_cloud_assets_viewer" {
  org_id = var.organisation_id
  role   = "roles/cloudasset.viewer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "sa_org_principal_access_bounday_viewer" {
  org_id = var.organisation_id
  role   = "roles/iam.principalAccessBoundaryViewer"
  member = "serviceAccount:${local.sa_email}"
}
