mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_main" {
  # Plan a terraform deployment for the main module
  # Catches module implementation errors in main.tf
  #   that wouldn't be caught by a syntax checker

  command = plan

  module {
    source = "./"
  }

  variables {
    project_id     = run.setup_tests.project_id
    products       = ["cloud-security-gcp", "flow-logs-gcp", "cloud-respond-gcp", "audit-logs-gcp", "fai-gcp"]
    region         = "europe-west2"
    aws_account_id = run.setup_tests.aws_account_id
    customer_id    = run.setup_tests.customer_id
    deployment_id  = run.setup_tests.deployment_id
  }

  override_data {
    target = data.google_project_ancestry.target_project_ancestry
    values = {
      ancestors = [
        { id = "hello-project-123456", type = "project" },
        { id = "12345678912", type = "organization" },
      ]
    }
  }
}
