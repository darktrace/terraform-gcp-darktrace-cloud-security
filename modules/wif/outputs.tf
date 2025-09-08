output "wip_id" {
  value = google_iam_workload_identity_pool.darktrace_pool.workload_identity_pool_id
}

output "wip_name" {
  value = split("/", local.wip_name)[length(split("/", local.wip_name)) - 1]
}

output "provider_id" {
  value = google_iam_workload_identity_pool_provider.darktrace_aws_provider.workload_identity_pool_provider_id
}
