locals {
  sa_name         = "darktrace-autonomous-response"
  sa_display_name = "Darktrace /CLOUD Autonomous Response"
  sa_email        = module.bound_service_account.sa_email
  role_prefix     = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
  roles = {
    "response_role" = google_organization_iam_custom_role.sa_org_response_role.name
  }
  scoped_deployment = length(var.allowed_projects) != 0
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

# denyAdmin is org-level only — always bound at org regardless of scoping
# We remove for scoped-deployments
resource "google_organization_iam_member" "sa_org_deny_admin" {
  count  = local.scoped_deployment ? 0 : 1
  org_id = var.organisation_id
  role   = "roles/iam.denyAdmin"
  member = module.bound_service_account.sa_member
}

## RESPOND ACTION PERMS
## Creating a role for Respond to test development functionality relative to soft deletion

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
    "storage.buckets.get",                # Get a specific storage bucket
    "storage.buckets.update",             # Update storage buckets (patch)
    "storage.buckets.setIamPolicy",       # Update storage bucket IAM policy
    "iam.roles.get",                      # Get an IAM role
    "iam.roles.update",                   # Update IAM role
    "iam.serviceAccounts.actAs",          # Required for patching services
    "run.services.get",                   # Get a cloud service
    "run.services.update",                # Update a cloud service
    "container.clusters.get",             # Required for getting clusters and node pools
    "container.clusters.update",          # Required for updating clusters and node pools
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "resourcemanager.organizations.getIamPolicy",
    "resourcemanager.organizations.setIamPolicy",
    "iam.serviceAccounts.disable",
    "iam.serviceAccounts.enable",
    "iam.serviceAccountKeys.disable",
    "iam.serviceAccountKeys.enable",
  ]
}

resource "google_organization_iam_member" "sa_org_binding" {
  # Create no org bindings if scoped, otherwise create all role bindings
  for_each = local.scoped_deployment ? {} : local.roles
  org_id   = var.organisation_id
  role     = each.value
  member   = module.bound_service_account.sa_member
}

module "scoped_project_bindings" {
  source   = "../../scoped_project_bindings"
  for_each = local.roles
  role_id  = each.value
  projects = var.allowed_projects
  member   = module.bound_service_account.sa_member
}
