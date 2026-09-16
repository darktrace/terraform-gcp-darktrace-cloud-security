# Reusable "managed log sink" stack shared by product modules (audit_logs, flow_logs, dns).
#
# Given a subscription-backed topic, this module creates:
#   - a PubSub topic and subscription
#   - a logging sink routing matching logs to that topic
#       * org-level sink for unscoped deployments (include_children)
#       * one per-project sink for scoped deployments
#   - roles/pubsub.publisher for each sink's writer identity so it can publish
#   - (optionally) roles/pubsub.subscriber for the consuming service account
#
# The subscriber binding is controlled independently of var.enabled: it may be
# needed even when no DT-managed sink stack is created — e.g. when a customer
# supplies their own subscription. Set subscriber_binding_enabled to create it
# (audit_logs can pass var.use_pubsub here; flow_logs passes true), supply the
# service account via subscriber_member, and optionally target a specific
# subscriber_project (defaults to publisher_project).

locals {
  # Create resources only when enabled by the caller (DT-managed / use_pubsub).
  create = var.enabled

  # Scoped deployments replace the org-level sink with per-project sinks.
  scoped_deployment = length(var.allowed_projects) != 0

  create_org_sink     = local.create && !local.scoped_deployment
  create_project_sink = local.create && local.scoped_deployment

  # Project set used for the per-project sinks and their writer bindings.
  project_sink_set = local.create_project_sink ? var.allowed_projects : []

  # Subscriber binding is independent of the sink stack. Gated solely on the
  # boolean so the count is known at plan time even when subscriber_member is a
  # computed value (e.g. a service account member resolved during apply).
  create_subscriber_binding = var.subscriber_binding_enabled

  # Fall back to the publisher project when no explicit subscriber project is given.
  subscriber_project = var.subscriber_project != "" ? var.subscriber_project : var.publisher_project
}

resource "google_pubsub_topic" "topic" {
  count = local.create ? 1 : 0
  name  = var.topic_name
}

resource "google_pubsub_subscription" "subscription" {
  count = local.create ? 1 : 0
  name  = var.subscription_name
  topic = google_pubsub_topic.topic[0].id
}

# Org-level sink for unscoped deployments — captures logs from all child projects
resource "google_logging_organization_sink" "org_sink" {
  count            = local.create_org_sink ? 1 : 0
  name             = var.sink_name
  org_id           = var.organisation_id
  description      = var.sink_description
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.topic[0].id}"
  filter           = var.sink_filter
  include_children = true

  dynamic "exclusions" {
    for_each = var.sink_exclusion == null ? [] : [var.sink_exclusion]
    content {
      name   = exclusions.value.name
      filter = exclusions.value.filter
    }
  }
}

# Per-project sinks for scoped deployments — one sink per allowed project
resource "google_logging_project_sink" "project_sink" {
  for_each    = local.project_sink_set
  project     = each.value
  name        = var.sink_name
  destination = "pubsub.googleapis.com/${google_pubsub_topic.topic[0].id}"
  filter      = var.sink_filter

  dynamic "exclusions" {
    for_each = var.sink_exclusion == null ? [] : [var.sink_exclusion]
    content {
      name   = exclusions.value.name
      filter = exclusions.value.filter
    }
  }
}

# The writer identity of the org sink must be able to publish to the topic
resource "google_project_iam_member" "org_sink_writer" {
  count   = local.create_org_sink ? 1 : 0
  project = var.publisher_project
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.org_sink[0].writer_identity
}

# Each per-project sink has its own writer identity that needs publish access
resource "google_project_iam_member" "project_sink_writer" {
  for_each = local.project_sink_set
  project  = var.publisher_project
  role     = "roles/pubsub.publisher"
  member   = google_logging_project_sink.project_sink[each.key].writer_identity
}

# The consuming service account needs subscriber access on the subscription's
# project. This is created independently of the sink stack so it also applies to
# customer-supplied subscriptions.
resource "google_project_iam_member" "subscriber" {
  count   = local.create_subscriber_binding ? 1 : 0
  project = local.subscriber_project
  role    = "roles/pubsub.subscriber"
  member  = var.subscriber_member
}
