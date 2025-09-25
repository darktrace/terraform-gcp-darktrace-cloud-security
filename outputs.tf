output "wif_pool_id" {
  value = module.wif.wip_id
}
output "wip_provider_id" {
  value = module.wif.provider_id
}
output "product_service_accounts" {
  value = merge(
    contains(local.formatted_products, "cloud_security_gcp") ? { "cloud-security-gcp" = module.cloud_security_gcp[0].sa_email } : {},
    contains(local.formatted_products, "flow_logs_gcp") ? { "flow-logs-gcp" = module.flow_logs_gcp[0].sa_email } : {}
  )
}
output "project_number" {
  value = var.project_number
}
output "organisation_id" {
  value = var.organisation_id
}

output "flowlogs_dt_managed" {
  value       = contains(local.formatted_products, "flow_logs_gcp") ? module.flow_logs_gcp[0].flow_logs_dt_managed : "not implemented"
  description = "Darktrace Flow Analysis is `dt_managed` if Darktrace creates its own infrastructure. Not implemented if flowlogs is not enabled"
}
