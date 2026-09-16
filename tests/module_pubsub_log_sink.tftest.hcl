mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Enabled + unscoped: one org-level sink, a topic and subscription, no per-project sinks
run "test_enabled_unscoped" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = true
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = []
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_description  = "Test sink"
    sink_filter       = "logName:\"logs/test\""
    publisher_project = run.setup_tests.project_id
  }

  assert {
    condition     = output.topics_created == 1
    error_message = "A single PubSub topic should be created when enabled"
  }

  assert {
    condition     = output.subscriptions_created == 1
    error_message = "A single PubSub subscription should be created when enabled"
  }

  assert {
    condition     = output.org_sinks_created == 1
    error_message = "An org-level sink should be created for unscoped deployments"
  }

  assert {
    condition     = output.project_sinks_created == 0
    error_message = "No per-project sinks should be created for unscoped deployments"
  }
}

# Enabled + scoped: one sink per allowed project, no org-level sink
run "test_enabled_scoped" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = true
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = run.setup_tests.allowed_projects
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_description  = "Test sink"
    sink_filter       = "logName:\"logs/test\""
    publisher_project = run.setup_tests.project_id
  }

  assert {
    condition     = output.topics_created == 1
    error_message = "A single PubSub topic should be created when enabled, regardless of scoping"
  }

  assert {
    condition     = output.subscriptions_created == 1
    error_message = "A single PubSub subscription should be created when enabled, regardless of scoping"
  }

  assert {
    condition     = output.org_sinks_created == 0
    error_message = "No org-level sink should be created for scoped deployments"
  }

  assert {
    condition     = output.project_sinks_created == length(run.setup_tests.allowed_projects)
    error_message = "One per-project sink should be created for each allowed project"
  }
}

# Disabled: no resources are created at all, even when allowed_projects is set
run "test_disabled" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = false
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = run.setup_tests.allowed_projects
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_description  = "Test sink"
    sink_filter       = "logName:\"logs/test\""
    publisher_project = run.setup_tests.project_id
  }

  assert {
    condition     = output.topics_created == 0
    error_message = "No topic should be created when the stack is disabled"
  }

  assert {
    condition     = output.subscriptions_created == 0
    error_message = "No subscription should be created when the stack is disabled"
  }

  assert {
    condition     = output.org_sinks_created == 0
    error_message = "No org-level sink should be created when the stack is disabled"
  }

  assert {
    condition     = output.project_sinks_created == 0
    error_message = "No per-project sinks should be created when the stack is disabled"
  }
}

# The exclusion filter is optional: the module plans cleanly with sink_exclusion unset (null)
run "test_no_exclusion" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = true
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = []
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_filter       = "logName:\"logs/test\""
    publisher_project = run.setup_tests.project_id
  }

  assert {
    condition     = output.org_sinks_created == 1
    error_message = "An org-level sink should be created even without an exclusion filter"
  }
}

# An exclusion filter can be supplied and does not change the number of sinks created
run "test_with_exclusion" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = true
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = []
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_filter       = "logName:\"logs/test\""
    sink_exclusion = {
      name   = "test_exclusion"
      filter = "resource.type=\"gce_instance\""
    }
    publisher_project = run.setup_tests.project_id
  }

  assert {
    condition     = output.org_sinks_created == 1
    error_message = "An org-level sink should be created when an exclusion filter is supplied"
  }
}

# By default no subscriber binding is created (subscriber_binding_enabled defaults to false)
run "test_subscriber_absent_by_default" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled           = true
    organisation_id   = run.setup_tests.organisation_id
    allowed_projects  = []
    topic_name        = "darktrace-test-topic"
    subscription_name = "darktrace-test-sub"
    sink_name         = "darktrace-test-sink"
    sink_filter       = "logName:\"logs/test\""
    publisher_project = run.setup_tests.project_id
    subscriber_member = run.setup_tests.sa_principal
  }

  assert {
    condition     = output.subscriber_bindings_created == 0
    error_message = "No subscriber binding should be created when subscriber_binding_enabled is left at its default (false)"
  }

  assert {
    condition     = output.subscriber_project == null
    error_message = "subscriber_project should be null when no binding is created"
  }
}

# A subscriber binding is created when enabled; project defaults to publisher_project
run "test_subscriber_defaults_to_publisher_project" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled                    = true
    organisation_id            = run.setup_tests.organisation_id
    allowed_projects           = []
    topic_name                 = "darktrace-test-topic"
    subscription_name          = "darktrace-test-sub"
    sink_name                  = "darktrace-test-sink"
    sink_filter                = "logName:\"logs/test\""
    publisher_project          = run.setup_tests.project_id
    subscriber_member          = run.setup_tests.sa_principal
    subscriber_binding_enabled = true
  }

  assert {
    condition     = output.subscriber_bindings_created == 1
    error_message = "A subscriber binding should be created when subscriber_binding_enabled is true"
  }

  assert {
    condition     = output.subscriber_project == run.setup_tests.project_id
    error_message = "subscriber_project should default to publisher_project when not set explicitly"
  }
}

# An explicit subscriber_project overrides the publisher_project default
run "test_subscriber_explicit_project" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled                    = true
    organisation_id            = run.setup_tests.organisation_id
    allowed_projects           = []
    topic_name                 = "darktrace-test-topic"
    subscription_name          = "darktrace-test-sub"
    sink_name                  = "darktrace-test-sink"
    sink_filter                = "logName:\"logs/test\""
    publisher_project          = run.setup_tests.project_id
    subscriber_member          = run.setup_tests.sa_principal
    subscriber_project         = "some-other-project-9999"
    subscriber_binding_enabled = true
  }

  assert {
    condition     = output.subscriber_project == "some-other-project-9999"
    error_message = "An explicit subscriber_project should override the publisher_project default"
  }
}

# The subscriber binding is independent of the sink stack: it can be created even
# when the managed infrastructure is disabled (customer-supplied subscription)
run "test_subscriber_when_stack_disabled" {
  command = plan

  module {
    source = "./modules/pubsub_log_sink"
  }

  variables {
    enabled                    = false
    organisation_id            = run.setup_tests.organisation_id
    allowed_projects           = []
    topic_name                 = "darktrace-test-topic"
    subscription_name          = "darktrace-test-sub"
    sink_name                  = "darktrace-test-sink"
    sink_filter                = "logName:\"logs/test\""
    publisher_project          = run.setup_tests.project_id
    subscriber_member          = run.setup_tests.sa_principal
    subscriber_binding_enabled = true
  }

  assert {
    condition     = output.topics_created == 0
    error_message = "No topic should be created when the stack is disabled"
  }

  assert {
    condition     = output.subscriber_bindings_created == 1
    error_message = "The subscriber binding should still be created when the stack is disabled"
  }
}
