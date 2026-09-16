mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_dt_managed" {
  # When `flow_logs_subscription` is empty, all DT-managed infrastructure should be created
  # This includes both flow logs and DNS pubsub resources

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

  # Flow Logs infrastructure
  assert {
    condition     = module.flow_logs_pubsub.topics_created > 0
    error_message = "Flow Logs Pub Sub Topic not created"
  }

  assert {
    condition     = module.flow_logs_pubsub.subscriptions_created > 0
    error_message = "Flow Logs Pub Sub Subscription not created"
  }

  assert {
    condition     = output.org_sinks_created > 0
    error_message = "Flow Logs Organisation Sink not created"
  }

  assert {
    condition     = output.project_sinks_created == 0
    error_message = "Flow Logs per-project sinks should not be created in unscoped deployments"
  }

  # DNS infrastructure
  assert {
    condition     = module.dns_logs_pubsub.topics_created > 0
    error_message = "DNS Pub Sub Topic not created"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriptions_created > 0
    error_message = "DNS Pub Sub Subscription not created"
  }

  assert {
    condition     = output.dns_org_sinks_created > 0
    error_message = "DNS Organisation Sink not created"
  }

  assert {
    condition     = output.dns_project_sinks_created == 0
    error_message = "DNS per-project sinks should not be created in unscoped deployments"
  }

  # Subscriber bindings are always created, even for DT-managed deployments
  assert {
    condition     = module.flow_logs_pubsub.subscriber_bindings_created == 1
    error_message = "Flow Logs subscriber binding should be created"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriber_bindings_created == 1
    error_message = "DNS subscriber binding should be created"
  }

  # With no dns_subscription, the DNS subscriber binding targets the deployment project
  assert {
    condition     = module.dns_logs_pubsub.subscriber_project == run.setup_tests.project_id
    error_message = "DNS subscriber binding should target the deployment project when no dns_subscription is set"
  }

  # With no flow_logs_subscription, the flow logs subscriber binding targets the deployment project
  assert {
    condition     = module.flow_logs_pubsub.subscriber_project == run.setup_tests.project_id
    error_message = "Flow Logs subscriber binding should target the deployment project when no flow_logs_subscription is set"
  }

  # Custom role
  assert {
    condition     = google_organization_iam_custom_role.sa_org_flow_logs_role[0].org_id == run.setup_tests.organisation_id
    error_message = "Flow Logs custom role not created in the correct organisation"
  }

  assert {
    condition     = contains(google_organization_iam_custom_role.sa_org_flow_logs_role[0].permissions, "dns.policies.get")
    error_message = "Flow Logs custom role missing dns.policies.get permission"
  }

  assert {
    condition     = length(google_organization_iam_custom_role.sa_org_flow_logs_role[0].permissions) == 4
    error_message = "Flow Logs custom role should have exactly 4 permissions"
  }
}

run "test_self_hosted" {
  # When `flow_logs_subscription` is provided, no DT-managed infrastructure should be created
  # This applies to both flow logs and DNS resources

  command = plan

  module {
    source = "./modules/product/flow_logs_gcp"
  }

  variables {
    organisation_id        = run.setup_tests.organisation_id
    project_id             = run.setup_tests.project_id
    principal              = run.setup_tests.sa_principal
    flow_logs_subscription = run.setup_tests.pubsub_subscription
    dns_subscription       = run.setup_tests.dns_pubsub_subscription
    custom_prefix          = ""
  }

  # Flow Logs infrastructure should not be created
  assert {
    condition     = module.flow_logs_pubsub.topics_created == 0
    error_message = "Flow Logs Pub Sub Topic should not be created in self-hosted mode"
  }

  assert {
    condition     = module.flow_logs_pubsub.subscriptions_created == 0
    error_message = "Flow Logs Pub Sub Subscription should not be created in self-hosted mode"
  }

  assert {
    condition     = output.org_sinks_created == 0
    error_message = "Flow Logs Organisation Sink should not be created in self-hosted mode"
  }

  # DNS infrastructure should not be created
  assert {
    condition     = module.dns_logs_pubsub.topics_created == 0
    error_message = "DNS Pub Sub Topic should not be created in self-hosted mode"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriptions_created == 0
    error_message = "DNS Pub Sub Subscription should not be created in self-hosted mode"
  }

  assert {
    condition     = output.dns_org_sinks_created == 0
    error_message = "DNS Organisation Sink should not be created in self-hosted mode"
  }

  # Subscriber bindings are still created in self-hosted mode (customer-supplied subs)
  assert {
    condition     = module.flow_logs_pubsub.subscriber_bindings_created == 1
    error_message = "Flow Logs subscriber binding should be created in self-hosted mode"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriber_bindings_created == 1
    error_message = "DNS subscriber binding should be created in self-hosted mode"
  }

  # Subscriber bindings target their respective self-hosted projects, which may differ
  assert {
    condition     = module.flow_logs_pubsub.subscriber_project == regex("^projects/([^/]+)/subscriptions/.*$", run.setup_tests.pubsub_subscription)[0]
    error_message = "Flow Logs subscriber binding should target the flow logs subscription project"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriber_project == regex("^projects/([^/]+)/subscriptions/.*$", run.setup_tests.dns_pubsub_subscription)[0]
    error_message = "DNS subscriber binding should target the DNS subscription project"
  }

  assert {
    condition     = module.dns_logs_pubsub.subscriber_project != module.flow_logs_pubsub.subscriber_project
    error_message = "DNS and flow logs subscriber bindings should target distinct projects when subscriptions differ"
  }

  # Custom role should still be created regardless
  assert {
    condition     = google_organization_iam_custom_role.sa_org_flow_logs_role[0].org_id == run.setup_tests.organisation_id
    error_message = "Flow Logs custom role should still be created in self-hosted mode"
  }
}
