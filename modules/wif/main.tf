resource "google_iam_workload_identity_pool" "darktrace_pool" {
  provider = google-beta

  workload_identity_pool_id = "darktrace-workload-identity-pool"
  display_name              = "Darktrace WIP"
  description               = "Darktrace uses Workload Identity Federation to obtain authorisation to access GCP resources"
  disabled                  = false
  mode                      = "FEDERATION_ONLY"
}

resource "google_iam_workload_identity_pool_provider" "darktrace_aws_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.darktrace_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "darktrace-aws-provider"
  display_name                       = "Darktrace AWS Identity Provider"
  description                        = "Darktrace authenticates with an internal AWS account that, here, is authenticated to access this project"
  attribute_mapping = {
    "attribute.aws_role" = "assertion.arn.extract(\"{account_arn}assumed-role/\") + \"assumed-role/\" + assertion.arn.extract(\"assumed-role/{role_name}/\")"
    "google.subject"     = "assertion.arn"
  }
  aws {
    account_id = var.aws_account_id
  }
}
locals {
  wip_name = google_iam_workload_identity_pool.darktrace_pool.workload_identity_pool_id
}
