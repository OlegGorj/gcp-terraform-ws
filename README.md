
# GCP infrastructure and services with Terraform

A few practice/test projects on Google Cloud using Terraform and Packer

## Step 1: Setup environment

Objectives:

- Create a Terraform admin project for the service account and a remote state bucket.
- Configure remote state in Google Cloud Storage (GCS).

Create GCP environment file in your home directory called `~/.gcp_env` with the following content

```
export GOOGLE_REGION=northamerica-northeast1  # whichever region you prefer
export TF_VAR_org_id=<this is your org id>
export TF_VAR_billing_account=<this is your billing account>
export TF_VAR_region=${GOOGLE_REGION}
export TF_VAR_user=${USER}
export TF_VAR_ssh_key=~/.ssh/dev_key.pub  # for example
export TF_ADMIN=tf-admin
export TF_CREDS=~/.config/gcloud/tf-admin.json

```

---
