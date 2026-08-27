## Creates and binds a custom role in each project
## Used for scoped (project-level) deployments, where an organisation-level
## custom role would grant Darktrace more scope than the customer requested.
## A project-level custom role can only be bound within its own project, so the
## role definition is duplicated across every allowed project under a shared role_id.
##
## Predefined roles cannot be created per project — bind those with
## modules/scoped_project_bindings instead.

## One role per scoped project
resource "google_project_iam_custom_role" "project_custom_roles" {
  for_each    = var.projects
  role_id     = var.role_id
  project     = each.value
  title       = var.title
  description = var.description
  permissions = var.permissions
}

## Binds the role created in each project to the service account
## Iterating the role resource keys the binding to the same project that owns
## the role, and makes the dependency explicit
resource "google_project_iam_member" "sa_project_bindings" {
  for_each = google_project_iam_custom_role.project_custom_roles
  project  = each.key
  role     = each.value.name
  member   = var.member
}
