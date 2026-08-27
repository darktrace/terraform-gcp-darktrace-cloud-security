locals {
  sa_name           = "darktrace-autonomous-response"
  sa_display_name   = "Darktrace /CLOUD Autonomous Response"
  sa_email          = module.bound_service_account.sa_email
  scoped_deployment = length(var.allowed_projects) != 0

  ### Role Parameters
  ### Reused for scoped vs org roles

  role_id          = "${local.role_prefix}darktrace.cloudRespondRole"
  role_title       = "Darktrace Autonomous Response Role"
  role_description = "Permissions required to perform and revert Autonomous Response Actions"
  role_permissions = ["compute.instances.get", # Describing instances
    "compute.instances.setTags",               # Setting network tags on instances
    "compute.firewalls.create",                # Creating VPC firewalls
    "compute.firewalls.list",                  # List VPC firewalls
    "compute.firewalls.get",                   # Required for patching firewall rules
    "compute.firewalls.update",                # Required for patching firewall rules
    "compute.firewalls.delete",                # Deleting VPC firewalls
    "compute.networks.updatePolicy",           # Creating + deleting firewalls
    "storage.buckets.get",                     # Get a specific storage bucket
    "storage.buckets.update",                  # Update storage buckets (patch)
    "storage.buckets.setIamPolicy",            # Update storage bucket IAM policy
    "iam.roles.get",                           # Get an IAM role
    "iam.roles.update",                        # Update IAM role
    "iam.serviceAccounts.actAs",               # Required for patching services
    "run.services.get",                        # Get a cloud service
    "run.services.update",                     # Update a cloud service
    "container.clusters.get",                  # Required for getting clusters and node pools
    "container.clusters.update",               # Required for updating clusters and node pools
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",

    "iam.serviceAccounts.disable",
    "iam.serviceAccounts.enable",
    "iam.serviceAccountKeys.disable",
    "iam.serviceAccountKeys.enable",
  ]

  # Only meaningful on an organisation-level role, so omitted from per-project roles.
  # Scoped deployments cannot manage organisation IAM policy
  org_only_permissions = [
    "resourcemanager.organizations.getIamPolicy",
    "resourcemanager.organizations.setIamPolicy",
  ]

  role_prefix = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

# denyAdmin is only assignable at the organisation level, so it cannot be scoped
# to individual projects. Scoped deployments therefore omit it entirely, and lose
# the ability to manage deny policies
resource "google_organization_iam_member" "sa_org_deny_admin" {
  count  = local.scoped_deployment ? 0 : 1
  org_id = var.organisation_id
  role   = "roles/iam.denyAdmin"
  member = module.bound_service_account.sa_member
}

## RESPOND ACTION PERMS
## The role granting Respond the permissions needed to perform and revert actions.
## Created at the organisation level for unscoped deployments, and once per allowed
## project for scoped deployments. Both paths share local.role_permissions

## ORG IAM
resource "google_organization_iam_custom_role" "sa_org_response_role" {
  count       = local.scoped_deployment ? 0 : 1
  role_id     = local.role_id
  org_id      = var.organisation_id
  title       = local.role_title
  description = local.role_description
  permissions = concat(local.role_permissions, local.org_only_permissions)
}

resource "google_organization_iam_member" "sa_org_binding" {
  # Create no org bindings if scoped, otherwise bind the org role
  count  = local.scoped_deployment ? 0 : 1
  org_id = var.organisation_id
  role   = google_organization_iam_custom_role.sa_org_response_role[0].name
  member = module.bound_service_account.sa_member
}

## PROJECT IAM

## One Role per scoped project
module "scoped_project_custom_role" {
  source      = "../../scoped_project_custom_role"
  projects    = var.allowed_projects
  role_id     = local.role_id
  member      = module.bound_service_account.sa_member
  title       = local.role_title
  description = local.role_description
  permissions = local.role_permissions
}
