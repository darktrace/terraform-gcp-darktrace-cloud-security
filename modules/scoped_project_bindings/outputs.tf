output "bindings_created" {
  value       = length(google_project_iam_member.project_iam_bindings)
  description = "The number of project level bindings created"
}
