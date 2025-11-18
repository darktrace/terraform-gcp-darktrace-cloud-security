locals {
  sa_name         = "darktrace-autonomous-response"
  sa_display_name = "Darktrace /CLOUD Autonomous Response"
  sa_email        = module.bound_service_account.sa_email
  role_prefix     = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

## RESPOND ACTION PERMS
## Creating a role for Respond to test development functionality relative to soft deletion

resource "google_organization_iam_custom_role" "sa_org_response_role" {
  role_id     = "${local.role_prefix}darktrace.cloudRespondRole"
  org_id      = var.organisation_id
  title       = "Darktrace Autonomous Response Role"
  description = "Permissions required to perform and revert Autonomous Response Actions"
  permissions = ["compute.instances.get", # Describing instances
    "compute.instances.setTags",          # Setting network tags on instances
    "compute.firewalls.create",           # Creating VPC firewalls
    "compute.firewalls.list",             # List VPC firewalls
    "compute.firewalls.get",              # Required for patching firewall rules
    "compute.firewalls.update",           # Required for patching firewall rules
    "compute.firewalls.delete",           # Deleting VPC firewalls
    "compute.networks.updatePolicy",      # Creating + deleting firewalls
  ]
}

# Binds the Service Account to the newly created role
resource "google_organization_iam_member" "sa_org_response_assignment" {
  org_id = var.organisation_id
  role   = google_organization_iam_custom_role.sa_org_response_role.name
  member = "serviceAccount:${local.sa_email}"
}
