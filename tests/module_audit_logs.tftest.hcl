mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_audit_logs_pubsub" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/audit_logs_gcp"
  }

  variables {
    organisation_id = run.setup_tests.organisation_id
    project_id      = run.setup_tests.project_id
    principal       = run.setup_tests.sa_principal
    use_pubsub      = true
    custom_prefix   = ""
  }

  assert {
    condition     = length(google_pubsub_subscription.audit_logs_sub) > 0
    error_message = "Audit Logs Pub Sub Subscription not created"
  }

  assert {
    condition     = length(google_logging_organization_sink.audit_logs_org_sink) > 0
    error_message = "Audit Logs Organisation Sink not created"
  }

  assert {
    condition     = length(google_pubsub_topic.audit_logs_topic) > 0
    error_message = "Audit Logs Pub Sub Topic not created"
  }

  assert {
    condition     = length(google_project_iam_member.sink_writer_iam) > 0
    error_message = "Audit Logs Sink Writer IAM binding not created"
  }
}

run "test_audit_logs_no_pubsub" {
  # if `audit_logs_subscription` is defined, log collection infrastructure should not be created
  command = plan

  module {
    source = "./modules/product/audit_logs_gcp"
  }

  variables {
    organisation_id = run.setup_tests.organisation_id
    project_id      = run.setup_tests.project_id
    principal       = run.setup_tests.sa_principal
    use_pubsub      = false
    custom_prefix   = ""
  }

  assert {
    condition     = length(google_pubsub_subscription.audit_logs_sub) == 0
    error_message = "Audit Logs Pub Sub Subscription not created"
  }

  assert {
    condition     = length(google_logging_organization_sink.audit_logs_org_sink) == 0
    error_message = "Audit Logs Organisation Sink not created"
  }

  assert {
    condition     = length(google_pubsub_topic.audit_logs_topic) == 0
    error_message = "Audit Logs Pub Sub Topic not created"
  }

  assert {
    condition     = length(google_project_iam_member.sink_writer_iam) == 0
    error_message = "Audit Logs Sink Writer IAM binding not created"
  }
}
