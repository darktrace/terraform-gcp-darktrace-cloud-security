locals {
  sa_name           = "darktrace-flow-analysis"
  sa_display_name   = "Darktrace /CLOUD Flow Analysis"
  sa_email          = module.bound_service_account.sa_email
  org_role_id       = "darktrace_flow_analysis_org_role"
  dt_managed        = var.flow_logs_subscription == ""
  flow_logs_project = local.dt_managed ? var.project_id : regex("^projects/([^/]+)/subscriptions/.*$", var.flow_logs_subscription)[0]
  role_prefix       = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
  roles = {
    "compute_network_viewer"           = "roles/compute.networkViewer"
    "browser"                          = "roles/browser"
    "networkmanagement_admin"          = "roles/networkmanagement.admin"
    "serviceusage_service_usage_admin" = "roles/serviceusage.serviceUsageAdmin"
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


# Give subscriber role in the project with the subscription
resource "google_project_iam_member" "sa_project_pubsub" {
  project = local.flow_logs_project
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${local.sa_email}"
}

# As far as we know, we only need these permissions for service usage admin
# networkmanagement.vpcflowlogsconfigs.create
# networkmanagement.vpcflowlogsconfigs.list
resource "google_organization_iam_member" "sa_org_bindings" {
  # Create no org bindings if scoped, otherwise create all role bindings
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
  count            = local.dt_managed ? 1 : 0
  name             = "${local.role_prefix}darktrace-flow-logs-sink"
  org_id           = var.organisation_id
  description      = "Routes VPC Flow Logs to Darktrace Flowlogs"
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.flow_logs_topic[0].id}"
  filter           = replace(var.logging_sink_filter, "\\u0022", "\"")
  include_children = true
}

# The writer identity of the sink must be able to write logs in the target project
# Existing setup assumes that the logs are properly written, so we don't need to add any role assignments
resource "google_project_iam_member" "sink_writer_iam" {
  count   = local.dt_managed ? 1 : 0
  project = local.flow_logs_project
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.flow_logs_org_sink[0].writer_identity
}
