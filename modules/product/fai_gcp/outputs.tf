output "sa_email" {
  value = local.sa_email
}

output "fai_dt_managed" {
  value = local.dt_managed
}

output "fai_gcs_bucket" {
  value = var.fai_gcs_bucket == "" ? google_storage_bucket.fai_gcs_bucket[0].name : var.fai_gcs_bucket
}
