resource "google_service_account" "sa" {
  account_id   = var.service_account_name
  display_name = "Service Account for ${var.service_account_display_name}"
  project      = var.project_id
}

# Service account must be a workloadIdentityUser
# GCP WIF checks the member field when authorising our request from AWS
resource "google_service_account_iam_member" "sa_role_assignment" {
  service_account_id = google_service_account.sa.id
  role               = "roles/iam.workloadIdentityUser"
  member             = var.principal
}

# SA requires project-level token creation perms
resource "google_project_iam_member" "sa_token_role_assignment" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.sa.email}"
}
