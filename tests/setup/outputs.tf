output "sa_principal" {
  value       = "principal://iam.googleapis.com/projects/12345678/locations/global/workloadIdentityPools/wip_name/subject/arn:aws:sts::${local.aws_account_id}:assumed-role/DarktraceGCPAuthRole/${local.customer_id}@${local.deployment_id}"
  description = "A valid principal for impersonating a service account via WIF"
}

output "pubsub_subscription" {
  value = "projects/my-pubsub-project-1234/subscriptions/test-sub"
}

output "organisation_id" {
  value       = "12345678912"
  description = "An organisation ID"
}

output "project_id" {
  value       = "hello-project-123456"
  description = "A test project ID, not existing within any of our organisations"
}

output "allowed_projects" {
  value       = ["hello-project-1234", "harryw-authman-test"]
  description = "Optional parameter, only set when needed"
}

output "aws_account_id" {
  value       = local.aws_account_id
  description = "aws account id that contains the gcp auth role"
}

output "customer_id" {
  value       = local.customer_id
  description = "The Customer's Customer ID, used in conjunction with the deployment id to format the WIF principal"
}

output "deployment_id" {
  value       = local.deployment_id
  description = "The customer's deployment ID, used in the principal for Workload Identity Federation"
}
