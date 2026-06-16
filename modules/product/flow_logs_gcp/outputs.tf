output "sa_email" {
  value = local.sa_email
}

output "flow_logs_dt_managed" {
  value = local.dt_managed
}

output "project_bindings_created" {
  value = sum([
    for m in module.scoped_project_bindings : m.bindings_created
  ])
  description = "Number of project-level bindings created. Should be |roles| * |projects|. Used for unit testing"
}

output "roles" {
  value       = local.roles
  description = "The roles bound at either the project or organisation level. Used for unit testing"
}

output "org_bindings_created" {
  value       = length(google_organization_iam_member.sa_org_bindings)
  description = "Number of org-level role bindings created. Should be 0 for scoped deployments. Used for unit testing"
}

output "project_sinks_created" {
  value       = length(google_logging_project_sink.flow_logs_project_sink)
  description = "Number of per-project logging sinks created. Used for unit testing"
}

output "org_sinks_created" {
  value       = length(google_logging_organization_sink.flow_logs_org_sink)
  description = "Number of org-level logging sinks created. Used for unit testing"
}
