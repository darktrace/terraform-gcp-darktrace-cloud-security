locals {
  sa_name           = "darktrace-flow-analysis"
  sa_display_name   = "Darktrace /CLOUD Flow Analysis"
  sa_email          = module.bound_service_account.sa_email
  dt_managed        = var.flow_logs_subscription == ""
  flow_logs_project = local.dt_managed ? var.project_id : regex("^projects/([^/]+)/subscriptions/.*$", var.flow_logs_subscription)[0]
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

  sink_filter = replace(var.logging_sink_filter, "\\u0022", "\"")
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}


# Give subscriber role in the project with the subscription
resource "google_project_iam_member" "sa_project_pubsub" {
  project = local.flow_logs_project
  role    = "roles/pubsub.subscriber"
  member  = module.bound_service_account.sa_member
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

resource "google_pubsub_topic" "flow_logs_topic" {
  count = local.dt_managed ? 1 : 0
  name  = "darktrace-flowlogs-topic"
}

resource "google_pubsub_subscription" "flow_logs_sub" {
  count = local.dt_managed ? 1 : 0
  name  = "darktrace-flow-logs-sub"
  topic = google_pubsub_topic.flow_logs_topic[0].id
}

resource "google_logging_organization_sink" "flow_logs_org_sink" {
  # Org-level sink for unscoped deployments — captures logs from all child projects
  count            = local.dt_managed && !local.scoped_deployment ? 1 : 0
  name             = "${local.role_prefix}darktrace-flow-logs-sink"
  org_id           = var.organisation_id
  description      = "Routes VPC Flow Logs to Darktrace Flowlogs"
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.flow_logs_topic[0].id}"
  filter           = local.sink_filter
  include_children = true
}

resource "google_logging_project_sink" "flow_logs_project_sink" {
  # Per-project sinks for scoped deployments — one sink per allowed project
  for_each    = local.dt_managed && local.scoped_deployment ? var.allowed_projects : []
  project     = each.value
  name        = "${local.role_prefix}darktrace-flow-logs-sink"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.flow_logs_topic[0].id}"
  filter      = local.sink_filter
}

# The writer identity of the sink must be able to write logs in the target project
resource "google_project_iam_member" "sink_writer_iam" {
  count   = local.dt_managed && !local.scoped_deployment ? 1 : 0
  project = local.flow_logs_project
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.flow_logs_org_sink[0].writer_identity
}

resource "google_project_iam_member" "sink_writer_iam_scoped" {
  # Each project sink has its own writer identity that needs publish access
  for_each = local.dt_managed && local.scoped_deployment ? var.allowed_projects : []
  project  = var.project_id
  role     = "roles/pubsub.publisher"
  member   = google_logging_project_sink.flow_logs_project_sink[each.key].writer_identity
}
