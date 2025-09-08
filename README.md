# Terraform GCP Darktrace Cloud Security

[![Terraform](https://img.shields.io/badge/Terraform-4B0082?logo=terraform)](https://www.terraform.io/)

Terraform modules for creating GCP infrastructure.

## Prerequisites

You will need the gcloud cli and terraform.

## Usage

To run this module, first create a `terraform.tfvars` in the main directory.

```bash
touch main/terraform.tfvars
echo 'region="europe-west2"
project_id="YOUR_PROJECT_NAME"
project_number=YOUR_PROJECTNUMBER
aws_account_id="CUSTPUBLIC_ACCOUNT_ID"
customer_id="YOUR_CUSTOMER_ID"
products=["cloud-security-gcp","flow-logs-gcp"]
' > terraform.tfvars
```

Authenticate GCloud and set your default project

```bash
gcloud auth login
gcloud config set project <your-project-id>
```

After filling in tfvars, run the following to create the infrastructure.

```bash
terraform plan
terraform apply
```

## Cleaning Terraform

To push to Google Infrastructure Manager, there can be no state files in the terraform.

```bash
rm -rf .terraform* terraform.tfstate terraform.tfstate.backup
```

---
