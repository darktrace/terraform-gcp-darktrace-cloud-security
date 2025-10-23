output "wif_pool_id" {
  value = module.wif.wip_id
}
output "wip_provider_id" {
  value = module.wif.provider_id
}
output "product_service_accounts" {
  value = merge(
    contains(var.products, "cloud-security-gcp") ? { "cloud-security-gcp" = module.cloud_security_gcp[0].sa_email } : {},
    contains(var.products, "flow-logs-gcp") ? { "flow-logs-gcp" = module.flow_logs_gcp[0].sa_email } : {},
    contains(var.products, "cloud-respond-gcp") ? { "cloud-respond-gcp" = module.cloud_respond_gcp[0].sa_email } : {},
    contains(var.products, "audit-logs-gcp") ? { "audit-logs-gcp" = module.audit_logs_gcp[0].sa_email } : {}
  )
}
output "project_number" {
  value = var.project_number
}

output "project_id" {
  value = var.project_id
}

output "organisation_id" {
  value = var.organisation_id
}

output "flowlogs_dt_managed" {
  value       = contains(var.products, "flow-logs-gcp") ? module.flow_logs_gcp[0].flow_logs_dt_managed : "not implemented"
  description = "Darktrace Flow Analysis is `dt_managed` if Darktrace creates its own infrastructure. Not implemented if flowlogs is not enabled"
}
