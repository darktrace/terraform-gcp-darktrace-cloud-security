output "bindings_created" {
  value       = length(google_project_iam_member.sa_project_bindings)
  description = "The number of project level bindings created. One per project"
}

output "roles_created" {
  value       = length(google_project_iam_custom_role.project_custom_roles)
  description = "The number of project level custom roles created. One per project"
}

output "role_names" {
  value       = { for project, role in google_project_iam_custom_role.project_custom_roles : project => role.name }
  description = "Map of project ID to the fully qualified name of the role created in that project"
}
