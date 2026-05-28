locals {
  sa_name         = "darktrace-core-service-account"
  sa_display_name = "Darktrace /CLOUD Enumeration"
  sa_email        = module.bound_service_account.sa_email
  role_prefix     = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
  bucket_prefix   = var.custom_prefix != "" ? "${var.custom_prefix}-" : ""
  roles = {
    "service_usage_consumer"           = "roles/serviceusage.serviceUsageConsumer"
    "cloudasset_viewer"                = "roles/cloudasset.viewer"
    "principal_access_boundary_viewer" = "roles/iam.principalAccessBoundaryViewer"
    "enumeration_role"                 = google_organization_iam_custom_role.sa_org_enumeration_role.name
  }
  scoped_deployment = length(var.allowed_projects) != 0
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal
  service_account_name         = local.sa_name
  service_account_display_name = local.sa_display_name
}

# If the customer elects to use scoped_deployment, then we use the scoped_project_bindings module
# Otherwise we bind the roles at the organisation level

module "scoped_project_bindings" {
  source   = "../../scoped_project_bindings"
  for_each = local.roles
  role_id  = each.value
  projects = var.allowed_projects
  member   = module.bound_service_account.sa_member
}

resource "google_organization_iam_member" "sa_org_bindings" {
  for_each = local.scoped_deployment ? {} : local.roles
  org_id   = var.organisation_id
  role     = each.value
  member   = module.bound_service_account.sa_member
}

## Cloud Core Role

# We use a separate role for enumeration from the storage role, as the storage role has a strict condition
resource "google_organization_iam_custom_role" "sa_org_enumeration_role" {
  role_id     = "${local.role_prefix}darktrace.cloudCoreEnumerationRole"
  org_id      = var.organisation_id
  title       = "Darktrace Cloud Core Enumeration Role"
  description = "Darktrace Role giving the Core Service Account access to asset API's"
  permissions = concat([
    "compute.backendServices.list",      # Extra data for Internal Load Balancers
    "bigquery.datasets.get",             # Extra data for BigQuery Datasets misconfigurations
    "compute.instanceGroups.get",        # Get instance group details
    "compute.instanceGroups.list",       # Get instances linked to unmanaged instance groups
    "compute.instanceGroupManagers.get", # Get managed instance group details
    "compute.instanceGroupManagers.list" # Get instances linked to managed instance groups
    ],
    # The Org cloudasset.viewer permission gives us access to projects and folders.
    # In scoped deployments we lack permission to view projects and folders, which are org-level resources
    local.scoped_deployment ? [
      "resourcemanager.projects.get",
    ] : []
  )
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
    enabled = var.enable_core_bucket_versioning
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
