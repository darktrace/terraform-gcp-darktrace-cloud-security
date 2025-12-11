output "sa_email" {
  value = google_service_account.sa.email
}

output "sa_member" {
  value       = google_service_account.sa.member
  description = "The member statement for the service account, is generally `serviceAccount:$email`"
}
