output "principal" {
  value = "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.wip_name}/subject/arn:aws:sts::${var.aws_account_id}:assumed-role/DarktraceGCPAuthRole/${var.customer_id}"
}
