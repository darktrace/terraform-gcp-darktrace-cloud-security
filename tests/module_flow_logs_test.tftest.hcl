mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_flow_logs_dt_managed" {
  # `flow_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/flow_logs_gcp"
  }

  variables {
    organisation_id        = run.setup_tests.organisation_id
    project_id             = run.setup_tests.project_id
    principal              = run.setup_tests.sa_principal
    flow_logs_subscription = ""
    custom_prefix          = ""
  }

  assert {
    condition     = length(google_pubsub_subscription.flow_logs_sub) > 0
    error_message = "Flow Logs Pub Sub Subscription not created"
  }

  assert {
    condition     = length(google_logging_organization_sink.flow_logs_org_sink) > 0
    error_message = "Flow Logs Organisation Sink not created"
  }

  assert {
    condition     = length(google_pubsub_topic.flow_logs_topic) > 0
    error_message = "Flow Logs Pub Sub Topic not created"
  }

  assert {
    condition     = length(google_project_iam_member.sink_writer_iam) > 0
    error_message = "Flow Logs Sink Writer IAM binding not created"
  }

  assert {
    condition     = google_organization_iam_custom_role.sa_org_flow_logs_role.org_id == run.setup_tests.organisation_id
    error_message = "Flow Logs custom role not created in the correct organisation"
  }

  assert {
    condition     = contains(google_organization_iam_custom_role.sa_org_flow_logs_role.permissions, "dns.policies.get")
    error_message = "Flow Logs custom role missing dns.policies.get permission"
  }

  assert {
    condition     = length(google_organization_iam_custom_role.sa_org_flow_logs_role.permissions) == 4
    error_message = "Flow Logs custom role should have exactly 4 permissions"
  }
}

run "test_flow_logs_self_hosted" {
  # if `flow_logs_subscription` is defined, log collection infrastructure should not be created
  command = plan

  module {
    source = "./modules/product/flow_logs_gcp"
  }

  variables {
    organisation_id        = run.setup_tests.organisation_id
    project_id             = run.setup_tests.project_id
    principal              = run.setup_tests.sa_principal
    flow_logs_subscription = run.setup_tests.pubsub_subscription
    custom_prefix          = ""
  }

  assert {
    condition     = length(google_pubsub_subscription.flow_logs_sub) == 0
    error_message = "Flow Logs Pub Sub Subscription not created"
  }

  assert {
    condition     = length(google_logging_organization_sink.flow_logs_org_sink) == 0
    error_message = "Flow Logs Organisation Sink not created"
  }

  assert {
    condition     = length(google_pubsub_topic.flow_logs_topic) == 0
    error_message = "Flow Logs Pub Sub Topic not created"
  }

  assert {
    condition     = length(google_project_iam_member.sink_writer_iam) == 0
    error_message = "Flow Logs Sink Writer IAM binding not created"
  }

  assert {
    condition     = google_organization_iam_custom_role.sa_org_flow_logs_role.org_id == run.setup_tests.organisation_id
    error_message = "Flow Logs custom role should still be created in self-hosted mode"
  }
}
