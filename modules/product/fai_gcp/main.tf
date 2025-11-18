locals {
  sa_name               = "darktrace-fai"
  sa_display_name       = "Darktrace /Forensic Acquisition & Investigation"
  sa_email              = module.bound_service_account.sa_email
  org_role_name         = "darktrace_fai_org_role"
  org_role_display_name = "Darktrace FAI Role"
  dt_managed            = var.fai_gcs_bucket == ""
  role_prefix           = var.custom_prefix != "" ? "${var.custom_prefix}." : ""
}

module "bound_service_account" {
  source                       = "../../bound_service_account"
  project_id                   = var.project_id
  principal                    = var.principal # This is the id of the principal assumed by GCPAuthRole AWS Role during WIF
  service_account_name         = "${local.role_prefix}${local.sa_name}"
  service_account_display_name = "${local.role_prefix}${local.sa_display_name}"
}

resource "google_organization_iam_custom_role" "fai_iam_org_role" {
  role_id     = "${local.role_prefix}${local.org_role_name}"
  org_id      = var.organisation_id
  title       = "${local.role_prefix}${local.org_role_display_name}"
  description = "Role used by /Forensic Acquisition & Investigation"
  permissions = [
    "cloudbuild.builds.create",
    "cloudbuild.builds.get",
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.setLabels",
    "compute.disks.use",
    "compute.disks.useReadOnly",
    "compute.globalOperations.get",
    "compute.images.create",
    "compute.images.get",
    "compute.images.useReadOnly",
    "compute.instances.create",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.machineTypes.list",
    "compute.networks.get",
    "compute.networks.list",
    "compute.projects.get",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.zoneOperations.get",
    "compute.zones.list",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "container.clusters.get",
    "container.clusters.list",
    "container.pods.exec",
    "container.pods.get",
    "container.pods.list",
    "iam.serviceAccounts.implicitDelegation",
    "iam.serviceAccounts.getAccessToken",
    "resourcemanager.projects.get",
    "iam.serviceAccounts.actAs",
    "compute.images.delete",
    "compute.instances.getSerialPortOutput",
    "compute.instances.delete",
    "compute.subnetworks.list",
    "compute.subnetworks.get",
  ]
}

resource "google_organization_iam_member" "sa_org_role_assignment" {
  org_id = var.organisation_id
  role   = google_organization_iam_custom_role.fai_iam_org_role.name
  member = "serviceAccount:${local.sa_email}"
}

resource "google_organization_iam_member" "default_compute_sa_role_assignment" {
  org_id = var.organisation_id
  role   = google_organization_iam_custom_role.fai_iam_org_role.name
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}


# **DT Managed Infrastructure**
resource "google_storage_bucket" "fai_gcs_bucket" {
  count         = local.dt_managed ? 1 : 0
  name          = substr("${var.custom_prefix == "" ? "" : "${var.custom_prefix}-"}${var.project_id}-darktrace_fai_bucket", 0, 63)
  location      = "US"
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}
