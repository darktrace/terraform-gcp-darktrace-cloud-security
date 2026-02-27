locals {
  sa_name         = "darktrace-core-service-account"
  sa_display_name = "Darktrace /CLOUD Enumeration"
  sa_email        = module.bound_service_account.sa_email
  role_prefix     = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
  bucket_prefix   = var.custom_prefix != "" ? "${var.custom_prefix}-" : ""
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

resource "google_organization_iam_member" "sa_org_service_usage_consumer" {
  org_id = var.organisation_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "sa_org_cloud_assets_viewer" {
  org_id = var.organisation_id
  role   = "roles/cloudasset.viewer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "sa_org_principal_access_bounday_viewer" {
  org_id = var.organisation_id
  role   = "roles/iam.principalAccessBoundaryViewer"
  member = "serviceAccount:${local.sa_email}"
}

## Enumeration Bucket Resources

# Create a separate role for bucket permissions so we can restrict it to our bucket
resource "google_project_iam_custom_role" "sa_project_cloud_core_bucket_role" {
  count       = var.create_core_bucket ? 1 : 0
  role_id     = "darktrace.cloudCoreRoleStorageRole"
  project     = var.project_id
  title       = "Darktrace Cloud Core Storage Role"
  description = "Darktrace Role giving the Core Service Account read and write permission to the Darktrace Bucket"
  permissions = [
    "storage.objects.get",
    "storage.objects.delete"
  ]
}

# Allow reading objects, but only in the cloud core bucket
resource "google_project_iam_binding" "sa_project_cloud_core_bucket_role_binding" {
  count   = var.create_core_bucket ? 1 : 0
  project = var.project_id
  role    = google_project_iam_custom_role.sa_project_cloud_core_bucket_role[0].name

  members = [
    module.bound_service_account.sa_member
  ]

  condition {
    title       = "limit_to_bucket"
    description = "Only allow access to the Cloud Core bucket"
    expression  = <<-EOT
      resource.name.startsWith("projects/_/buckets/${google_storage_bucket.cloud_core_bucket[0].name}")
    EOT
  }
}

# Our SAST insists that logging is required on a storage bucket, but storage logging is specifically discouraged by GCP
# https://docs.cloud.google.com/storage/docs/access-logs#use-monitoring
# TODO Customise SAST in yml file
# kics-scan ignore-block
resource "google_storage_bucket" "cloud_core_bucket" {
  count = var.create_core_bucket ? 1 : 0
  # Bucket names must be unique organisation-wide
  name          = "${local.bucket_prefix}darktrace-cloud-core-bucket-${var.organisation_id}"
  location      = var.bucket_location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 7
    }
  }

  force_destroy = true
}
