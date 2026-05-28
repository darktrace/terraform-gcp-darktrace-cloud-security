# creates a role binding in each of the enabled projects for each defined role
resource "google_project_iam_member" "project_iam_bindings" {
  for_each = var.projects
  project  = each.value
  role     = var.role_id
  member   = var.member
}
