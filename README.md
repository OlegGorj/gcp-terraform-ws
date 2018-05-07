
# GCP infrastructure and services with Terraform

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/4b6ede56298049ec87e5c0556304aec9)](https://app.codacy.com/app/oleggorj/gcp-terraform-ws?utm_source=github.com&utm_medium=referral&utm_content=OlegGorj/gcp-terraform-ws&utm_campaign=badger)

A few practice/test projects on Google Cloud using Terraform and Packer

---

# Project 1 - Admin project in GCP

Objectives:

- Create a Terraform admin project for the service account and a remote state bucket
- Link root project to billing account
- Create service Terraform account
- Configure remote state in Google Cloud Storage (GCS)

## Step 1: Setup environment


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

# and this two at the end before tf init
export GOOGLE_PROJECT=${TF_PROJECT_ID}
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}

```

## Step 2: clone repo

```
git clone https://github.com/OlegGorj/gcp-terraform-ws.git
```

## Step 3: Using GCP CLI create Host project, service account and generate Terraform code to store the state at the backend bucket

```
cd gcp-terraform-ws/project1-gcp-cli/

./init_setup.sh ~/.gcp_env
```

## Step 4: Initialize TF environment and plan

```
terraform init

terraform plan
```

At this point, your TF with GCP as provider and backend, is setup and ready to go.

---
