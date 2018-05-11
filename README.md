
# GCP infrastructure and services with Terraform

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
export GOOGLE_REGION=<your GCP region>  # whichever region you prefer e.g. northamerica-northeast1
export TF_ENV=<your environment e.g. dev, test, prod>
export TF_VAR_org_id=<this is your org id>
export TF_VAR_billing_account=<this is your billing account>
export TF_VAR_region=${GOOGLE_REGION}
export TF_VAR_user=${USER}
export TF_VAR_ssh_key=<pub key>  # pub key file e.g. ~/.ssh/dev_key.pub
export TF_FOLDER=${TF_ENV}_projects
export TF_ADMIN=tf-admin
export TF_CREDS=~/.config/gcloud/tf-admin.json

# and this two at the end before tf init
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}

export GOOGLE_ADMIN_DOMAIN=<your domain>
export GOOGLE_ADMIN_ACCOUNT=<admin account of your domain>

```

## Step 2: clone repo

```
git clone https://github.com/OlegGorj/gcp-terraform-ws.git
```

## Step 3: Using GCP CLI create Host project, service account and generate Terraform code to store the state at the backend bucket

Set of commands bellow does the following:

- Attempt to connect to GCP using provided credentials
- Create folder under root (i.e. organization) `TF_FOLDER`
- Generate `admin` project (main project that will host rest of projects) in the folder `TF_FOLDER` and store project ID in `TF_PROJECT_ID`
- Link `admin` (root) project to billing account
- Create Terraform service account, cut new keys and bind service account to multiple IAM roles
- Enable 4 APIs for `admin` project: cloudresourcemanager, cloudbilling, iam, compute, sqladmin


```
cd gcp-terraform-ws/

./init_setup.sh ~/.gcp_env
```

## Step 4: Initialize TF environment and plan

```
terraform init

terraform plan
```

At this point, your TF with GCP as provider and backend, is setup and ready to go.

---
