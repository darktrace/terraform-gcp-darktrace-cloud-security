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
}
