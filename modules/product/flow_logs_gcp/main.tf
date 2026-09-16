locals {
  sa_name           = "darktrace-flow-analysis"
  sa_display_name   = "Darktrace /CLOUD Flow Analysis"
  sa_email          = module.bound_service_account.sa_email
  dt_managed        = var.flow_logs_subscription == "" && var.dns_subscription == ""
  flow_logs_project = var.flow_logs_subscription == "" ? var.project_id : regex("^projects/([^/]+)/subscriptions/.*$", var.flow_logs_subscription)[0]
  dns_logs_project  = var.dns_subscription == "" ? var.project_id : regex("^projects/([^/]+)/subscriptions/.*$", var.dns_subscription)[0]
  role_prefix       = var.custom_prefix != "" ? "${var.custom_prefix}." : ""

  scoped_deployment = length(var.allowed_projects) != 0

  # Predefined roles cannot be defined per project, so they are bound as-is:
  # at the organisation level when unscoped, per project when scoped
  # As far as we know, we only need these permissions for service usage admin
  # networkmanagement.vpcflowlogsconfigs.create
  # networkmanagement.vpcflowlogsconfigs.list
  predefined_roles = {
    "compute_network_viewer"           = "roles/compute.networkViewer"
    "browser"                          = "roles/browser"
    "networkmanagement_admin"          = "roles/networkmanagement.admin"
    "serviceusage_service_usage_admin" = "roles/serviceusage.serviceUsageAdmin"
  }

  ### Role Parameters
  ### Reused for scoped vs org roles
  ### No project-only permissions are needed: roles/browser is bound in every
  ### allowed project and already grants project visibility

  role_id          = "${local.role_prefix}darktrace.flowAnalysisRole"
  role_title       = "Darktrace Flow Analysis Role"
  role_description = "Permissions for Darktrace ⁄ CLOUD to consume DNS Flow Logs"
  role_permissions = [
    "dns.policies.get", # Reading DNS Policies if they exist, and create them if not
    "dns.policies.list",
    "dns.policies.create",
    "logging.logEntries.list" # Consume DNS Events
  ]

  sink_filter     = replace(var.logging_sink_filter, "\\u0022", "\"")
  dns_sink_filter = replace(var.dns_logging_sink_filter, "\\u0022", "\"")
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}


## FLOW ANALYSIS ROLE
## Created at the organisation level for unscoped deployments, and once per allowed
## project for scoped deployments. Both paths share local.role_permissions

## ORG IAM
resource "google_organization_iam_custom_role" "sa_org_flow_logs_role" {
  count       = local.scoped_deployment ? 0 : 1
  role_id     = local.role_id
  org_id      = var.organisation_id
  title       = local.role_title
  description = local.role_description
  permissions = local.role_permissions
}

resource "google_organization_iam_member" "sa_org_flow_logs_binding" {
  # Create no org bindings if scoped, otherwise bind the org role
  count  = local.scoped_deployment ? 0 : 1
  org_id = var.organisation_id
  role   = google_organization_iam_custom_role.sa_org_flow_logs_role[0].name
  member = module.bound_service_account.sa_member
}

## PREDEFINED ROLES

resource "google_organization_iam_member" "sa_org_bindings" {
  # Create no org bindings if scoped, otherwise create all role bindings
  for_each = local.scoped_deployment ? {} : local.predefined_roles
  org_id   = var.organisation_id
  role     = each.value
  member   = module.bound_service_account.sa_member
}

module "scoped_project_bindings" {
  source   = "../../scoped_project_bindings"
  for_each = local.predefined_roles
  role_id  = each.value
  projects = var.allowed_projects
  member   = module.bound_service_account.sa_member
}

## PROJECT IAM

## One flow analysis role per scoped project
module "scoped_project_custom_role" {
  source      = "../../scoped_project_custom_role"
  projects    = var.allowed_projects
  role_id     = local.role_id
  member      = module.bound_service_account.sa_member
  title       = local.role_title
  description = local.role_description
  permissions = local.role_permissions
}

# **DT Managed Infrastructure**
# The topic + subscription + logging sink + sink-writer IAM flow is shared with
# audit_logs_gcp and is encapsulated in the pubsub_log_sink module.

module "flow_logs_pubsub" {
  source            = "../../pubsub_log_sink"
  enabled           = local.dt_managed
  organisation_id   = var.organisation_id
  allowed_projects  = var.allowed_projects
  topic_name        = "darktrace-flowlogs-topic"
  subscription_name = "darktrace-flow-logs-sub"
  sink_name         = "${local.role_prefix}darktrace-flow-logs-sink"
  sink_description  = "Routes VPC Flow Logs to Darktrace Flowlogs"
  sink_filter       = local.sink_filter
  publisher_project = local.flow_logs_project
  # Subscriber access is granted in the subscription's project regardless of
  # whether the DT-managed stack is created (customers may bring their own sub).
  subscriber_member          = module.bound_service_account.sa_member
  subscriber_project         = local.flow_logs_project
  subscriber_binding_enabled = true
}

# **DT Managed DNS Infrastructure**

module "dns_logs_pubsub" {
  source            = "../../pubsub_log_sink"
  enabled           = local.dt_managed
  organisation_id   = var.organisation_id
  allowed_projects  = var.allowed_projects
  topic_name        = "darktrace-dns-logs-topic"
  subscription_name = "darktrace-dns-logs-sub"
  sink_name         = "${local.role_prefix}darktrace-dns-logs-sink"
  sink_description  = "Routes DNS Query Logs to Darktrace Flowlogs"
  sink_filter       = local.dns_sink_filter
  publisher_project = var.project_id
  # DNS subscriber access is granted in the DNS subscription's project.
  subscriber_member          = module.bound_service_account.sa_member
  subscriber_project         = local.dns_logs_project
  subscriber_binding_enabled = true
}
