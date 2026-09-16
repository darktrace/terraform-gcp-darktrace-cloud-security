output "sa_email" {
  value = local.sa_email
}

output "flow_logs_dt_managed" {
  value = local.dt_managed
}

output "project_bindings_created" {
  value = sum(concat(
    [for m in module.scoped_project_bindings : m.bindings_created],
    [module.scoped_project_custom_role.bindings_created]
  ))
  description = "Number of project-level bindings created. Should be |roles| * |projects|. Used for unit testing"
}

output "project_roles_created" {
  value       = module.scoped_project_custom_role.roles_created
  description = "Number of project-level custom roles created. One per allowed project. Used for unit testing"
}

output "roles" {
  value       = concat(values(local.predefined_roles), [local.role_id])
  description = "The distinct roles granted to the service account, bound at either the project or organisation level. Used for unit testing"
}

output "org_bindings_created" {
  value = length(google_organization_iam_member.sa_org_bindings) + length(google_organization_iam_member.sa_org_flow_logs_binding)

  description = "Number of org-level role bindings created. Should be 0 for scoped deployments. Used for unit testing"
}

output "project_sinks_created" {
  value       = module.flow_logs_pubsub.project_sinks_created
  description = "Number of per-project logging sinks created. Used for unit testing"
}

output "org_sinks_created" {
  value       = module.flow_logs_pubsub.org_sinks_created
  description = "Number of org-level logging sinks created. Used for unit testing"
}

output "dns_project_sinks_created" {
  value       = module.dns_logs_pubsub.project_sinks_created
  description = "Number of per-project DNS logging sinks created. Used for unit testing"
}

output "dns_org_sinks_created" {
  value       = module.dns_logs_pubsub.org_sinks_created
  description = "Number of org-level DNS logging sinks created. Used for unit testing"
}
