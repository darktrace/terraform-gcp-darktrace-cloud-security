mock_provider "google" {}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

run "test_cloud_security_bucket" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/cloud_security_gcp"
  }

  variables {
    organisation_id    = run.setup_tests.organisation_id
    project_id         = run.setup_tests.project_id
    principal          = run.setup_tests.sa_principal
    custom_prefix      = ""
    create_core_bucket = true
    bucket_location    = run.setup_tests.region
  }

  assert {
    condition     = length(google_project_iam_custom_role.sa_project_cloud_core_bucket_role) == 1
    error_message = "Cloud Security Module failed to create core bucket project role when create_core_bucket is true"
  }

  assert {
    condition     = length(google_storage_bucket.cloud_core_bucket) == 1
    error_message = "Cloud Security Module failed to create core bucket when create_core_bucket is true"
  }

  assert {
    condition     = google_storage_bucket.cloud_core_bucket[0].name == "darktrace-cloud-core-bucket-${run.setup_tests.organisation_id}"
    error_message = "Bucket name pattern does not match. Bucket names must be GLOBALLY unique across all of GCP"
  }
}

run "test_cloud_security_no_bucket" {
  # `audit_logs_subscription` being an empty string should create various resources in the target project

  command = plan

  module {
    source = "./modules/product/cloud_security_gcp"
  }

  variables {
    organisation_id    = run.setup_tests.organisation_id
    project_id         = run.setup_tests.project_id
    principal          = run.setup_tests.sa_principal
    custom_prefix      = ""
    create_core_bucket = false
    bucket_location    = run.setup_tests.region
  }

  assert {
    condition     = length(google_project_iam_custom_role.sa_project_cloud_core_bucket_role) == 0
    error_message = "Cloud Security Module created core bucket project role when create_core_bucket is false"
  }

  assert {
    condition     = length(google_storage_bucket.cloud_core_bucket) == 0
    error_message = "Cloud Security Module created core bucket when create_core_bucket is false"
  }
}
