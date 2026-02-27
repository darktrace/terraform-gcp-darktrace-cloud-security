output "sa_email" {
  value = local.sa_email
}

output "cloud_core_bucket_name" {
  value = var.create_core_bucket ? google_storage_bucket.cloud_core_bucket[0].name : null
}
