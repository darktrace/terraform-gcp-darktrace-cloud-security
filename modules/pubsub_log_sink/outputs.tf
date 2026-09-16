output "topic_id" {
  value       = local.create ? google_pubsub_topic.topic[0].id : null
  description = "The id of the created PubSub topic, or null when the stack is disabled"
}

output "subscription_id" {
  value       = local.create ? google_pubsub_subscription.subscription[0].id : null
  description = "The id of the created PubSub subscription, or null when the stack is disabled"
}

output "topics_created" {
  value       = length(google_pubsub_topic.topic)
  description = "Number of PubSub topics created (0 or 1). Known at plan time; used for unit testing"
}

output "subscriptions_created" {
  value       = length(google_pubsub_subscription.subscription)
  description = "Number of PubSub subscriptions created (0 or 1). Known at plan time; used for unit testing"
}

output "org_sinks_created" {
  value       = length(google_logging_organization_sink.org_sink)
  description = "Number of org-level logging sinks created. Used for unit testing"
}

output "project_sinks_created" {
  value       = length(google_logging_project_sink.project_sink)
  description = "Number of per-project logging sinks created. Used for unit testing"
}

output "subscriber_bindings_created" {
  value       = length(google_project_iam_member.subscriber)
  description = "Number of subscriber bindings created (0 or 1). Known at plan time; used for unit testing"
}

output "subscriber_project" {
  value       = local.create_subscriber_binding ? local.subscriber_project : null
  description = "The project the subscriber binding targets, or null when no binding is created"
}
