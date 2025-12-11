locals {
  sa_name         = "darktrace-audit-logs"
  sa_display_name = "Darktrace /CLOUD Audit Logs"
  # add a trailing dot to match GCP recommended syntax
  asset_prefix = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
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
  member = module.bound_service_account.sa_member
}

resource "google_organization_iam_member" "sa_org_priv_logs" {
  org_id = var.organisation_id
  role   = "roles/logging.privateLogViewer"
  member = module.bound_service_account.sa_member
}

# PubSub Infrastructure

resource "google_pubsub_topic" "audit_logs_topic" {
  count = var.use_pubsub ? 1 : 0
  name  = "darktrace-audit-logs-topic"
}

resource "google_pubsub_subscription" "audit_logs_sub" {
  count = var.use_pubsub ? 1 : 0
  name  = "darktrace-audit-logs-sub"
  topic = google_pubsub_topic.audit_logs_topic[0].id
}

resource "google_logging_organization_sink" "audit_logs_org_sink" {
  count       = var.use_pubsub ? 1 : 0
  name        = "${local.asset_prefix}darktrace-audit-logs-sink"
  org_id      = var.organisation_id
  description = "Routes VPC Audit Logs to Darktrace Flowlogs"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_logs_topic[0].id}"
  filter      = "LOG_ID(\"cloudaudit.googleapis.com/data_access\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\")"
  exclusions {
    name   = "audit_logs"
    filter = "resource.type=('logging_log' OR 'k8s_cluster') OR protoPayload.methodName=('google.container.v1.ClusterManager.ListClusters' OR 'beta.compute.snapshots.list' OR 'v1.compute.routes.list' OR 'google.logging.v2.LoggingServiceV2.ListLogs' OR 'google.iam.v1.IAMPolicy.GetIamPolicy' OR 'google.cloud.functions.v1.CloudFunctionsService.GetIamPolicy' OR 'beta.compute.instanceGroupManagers.listManagedInstances' OR 'beta.compute.instances.listReferrers' OR 'google.pubsub.v1.Publisher.ListTopics' OR 'google.monitoring.v3.MetricService.CreateTimeSeries' OR 'List' OR 'google.pubsub.v1.Publisher.ListTopicSnapshots' OR 'google.logging.v2.LoggingServiceV2.ListLogEntries' OR 'storage.buckets.list' OR 'google.cloud.location.Locations.ListLocations' OR 'beta.compute.projects.get' OR 'google.iam.admin.v1.QueryGrantableRoles' OR 'beta.compute.addresses.aggregatedList' OR 'google.firestore.v1.Firestore.Listen' OR 'google.pubsub.v1.Publisher.ListTopicSubscriptions' OR 'google.container.v1beta1.ClusterManager.GetOperation' OR 'beta.compute.firewalls.list' OR 'v1.compute.instanceGroups.list' OR 'v1.compute.backendServices.list' OR 'v1.compute.instances.aggregatedList' OR 'google.iam.admin.v1.GetPolicyDetails' OR 'v1.compute.backendServices.get' OR 'google.iam.admin.v1.ListServiceAccountKeys' OR 'google.logging.v2.LoggingServiceV2.ListResourceKeys' OR 'cloudsql.instances.list' OR 'iam.roles.list' OR 'GetResourceBillingInfo' OR 'google.container.v1beta1.ClusterManager.ListClusters' OR 'google.iam.admin.v1.GetServiceAccount' OR 'v1.compute.networks.list' OR 'google.logging.v2.LoggingServiceV2.ReadLogEntriesLegacy' OR 'v1.compute.projects.get' OR 'v1.compute.instanceGroupManagers.listManagedInstances' OR 'v1.compute.zoneOperations.get' OR 'google.iam.admin.v1.ListServiceAccounts' OR 'google.cloud.functions.v1.CloudFunctionsService.ListFunctions' OR 'GetProjectBillingInfo' OR 'google.logging.v2.BillingService.GetUsageByResourceType' OR 'GetProject' OR 'beta.compute.instanceGroupManagers.get' OR 'GetOrganization' OR 'google.monitoring.v3.MetricService.CreateServiceTimeSeries')"
  }
  include_children = true
}

# The writer identity of the sink must be able to write logs in the target project
resource "google_project_iam_member" "sink_writer_iam" {
  count   = var.use_pubsub ? 1 : 0
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.audit_logs_org_sink[0].writer_identity
}

resource "google_project_iam_member" "sa_project_pubsub" {
  count   = var.use_pubsub ? 1 : 0
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = module.bound_service_account.sa_member
}
