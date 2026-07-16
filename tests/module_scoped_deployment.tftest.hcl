mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_audit_logs_scoped_deployment" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/audit_logs_gcp"
  }

  variables {
    organisation_id  = run.setup_tests.organisation_id
    project_id       = run.setup_tests.project_id
    principal        = run.setup_tests.sa_principal
    allowed_projects = run.setup_tests.allowed_projects
    use_pubsub       = true
    custom_prefix    = ""
  }

  assert {
    # Equal to the number of roles times the number of allowed projects
    condition     = output.project_bindings_created == length(run.setup_tests.allowed_projects) * length(output.roles)
    error_message = "Incorrect number of project bindings created"
  }

  assert {
    condition     = output.org_bindings_created == 0
    error_message = "Org-level bindings should not be created in scoped deployments"
  }

  assert {
    condition     = output.org_sinks_created == 0
    error_message = "Org-level sinks should not be created in scoped deployments"
  }

  assert {
    condition     = output.project_sinks_created == length(run.setup_tests.allowed_projects)
    error_message = "Per-project sinks should be created for each allowed project"
  }
}

run "test_cloud_security_scoped_deployment" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/cloud_security_gcp"
  }

  variables {
    organisation_id  = run.setup_tests.organisation_id
    project_id       = run.setup_tests.project_id
    principal        = run.setup_tests.sa_principal
    allowed_projects = run.setup_tests.allowed_projects
    custom_prefix    = ""
    bucket_location  = run.setup_tests.region
  }

  assert {
    # Equal to the number of roles times the number of allowed projects
    condition     = output.project_bindings_created == length(run.setup_tests.allowed_projects) * length(output.roles)
    error_message = "Incorrect number of project bindings created"
  }

  assert {
    condition     = output.org_bindings_created == 0
    error_message = "Org-level bindings should not be created in scoped deployments"
  }
}

run "test_flow_logs_scoped_deployment" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/flow_logs_gcp"
  }

  variables {
    organisation_id  = run.setup_tests.organisation_id
    project_id       = run.setup_tests.project_id
    principal        = run.setup_tests.sa_principal
    allowed_projects = run.setup_tests.allowed_projects
    custom_prefix    = ""
  }

  assert {
    # Equal to the number of roles times the number of allowed projects
    condition     = output.project_bindings_created == length(run.setup_tests.allowed_projects) * length(output.roles)
    error_message = "Incorrect number of project bindings created"
  }

  assert {
    condition     = output.org_bindings_created == 0
    error_message = "Org-level bindings should not be created in scoped deployments"
  }

  assert {
    condition     = output.org_sinks_created == 0
    error_message = "Org-level sinks should not be created in scoped deployments"
  }

  assert {
    condition     = output.project_sinks_created == length(run.setup_tests.allowed_projects)
    error_message = "Per-project sinks should be created for each allowed project"
  }
}
