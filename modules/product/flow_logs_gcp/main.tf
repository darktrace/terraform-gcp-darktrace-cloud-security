locals {
  sa_name           = "darktrace-flow-analysis"
  sa_display_name   = "Darktrace /CLOUD Flow Analysis"
  sa_email          = module.bound_service_account.sa_email
  org_role_id       = "darktrace_flow_analysis_org_role"
  dt_managed        = var.flow_logs_subscription == ""
  flow_logs_project = local.dt_managed ? var.project_id : regex("^projects/([^/]+)/subscriptions/.*$", var.flow_logs_subscription)[0]
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

resource "google_organization_iam_member" "sa_org_bindings" {
  org_id = var.organisation_id
  role   = "roles/compute.networkViewer"
  member = "serviceAccount:${local.sa_email}"
}

# Give subscriber role in the project with the subscription
resource "google_project_iam_member" "sa_project_pubsub" {
  project = local.flow_logs_project
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${local.sa_email}"
}

# For iterating through projects, finding subnets
resource "google_organization_iam_member" "sa_org_browser" {
  org_id = var.organisation_id
  role   = "roles/browser"
  member = "serviceAccount:${local.sa_email}"
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
  name             = "darktrace-flow-logs-sink"
  org_id           = var.organisation_id
  description      = "Routes VPC Flow Logs to Darktrace Flowlogs"
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.flow_logs_topic[0].id}"
  filter           = "logName:\"logs/compute.googleapis.com%2Fvpc_flows\" -jsonPayload.src_google_service.type=\"GOOGLE_API\" -jsonPayload.dest_google_service.type=\"GOOGLE_API\""
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
