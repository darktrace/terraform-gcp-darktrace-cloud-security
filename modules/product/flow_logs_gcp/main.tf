locals {
  sa_name         = "darktrace-flow-analysis"
  sa_display_name = "Darktrace /CLOUD Flow Analysis"
  sa_email        = module.bound_service_account.sa_email
  org_role_id     = "darktrace_flow_analysis_org_role"
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

# resource "google_organization_iam_custom_role" "org_custom_role" {
#   role_id     = local.org_role_id
#   org_id      = var.organisation_id # Replace with your org ID
#   title       = "Flow Analysis Custom Role"
#   description = "${local.sa_display_name} Custom Role"
#   permissions = [
#     # all that is needed for consuming flow logs
#     "pubsub.subscriptions.consume",
#     # For setting up flowlogs, requires iterating through projects and the org to find and update subnetworks,
#     "compute.subnetworks.get",
#     "compute.subnetworks.update",
#     "resourcemanager.organizations.get",
#     "resourcemanager.projects.get",
#     "resourcemanager.projects.list",
#   ]
# }

# We require org-level permissions to perform key tasks
resource "google_organization_iam_member" "sa_org_bindings" {
  org_id = var.organisation_id
  role   = "roles/compute.networkViewer"
  member = "serviceAccount:${local.sa_email}"
}

# Will be changed to project-level when we deploy all flowlogs infra
resource "google_organization_iam_member" "sa_org_pubsub" {
  org_id = var.organisation_id
  role   = "roles/pubsub.subscriber"
  member = "serviceAccount:${local.sa_email}"
}

# For iterating through projects, finding subnets
resource "google_organization_iam_member" "sa_org_browser" {
  org_id = var.organisation_id
  role   = "roles/browser"
  member = "serviceAccount:${local.sa_email}"
}
