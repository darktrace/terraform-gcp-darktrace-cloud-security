output "sa_email" {
  value = local.sa_email
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
  value       = length(google_organization_iam_member.sa_org_binding)
  description = "Number of org-level role bindings created. Should be 0 for scoped deployments. Used for unit testing"
}
