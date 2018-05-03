#!/bin/bash -e

export GCPfile=$1

SERVICE_ACCOUNT=terraform

if [ -f $GCPfile ]; then
   . ${GCPfile}
else
  echo "File doesn't exist: " ${GCPfile}
  exit 1
fi

echo "INFO: Listing organizations:"
gcloud beta organizations list

echo "INFO: Listing billing accounts:"
gcloud alpha billing accounts list

RANDOMID=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 9 ; echo)
TF_PROJECT_ID="${TF_ADMIN}-${RANDOMID}"

echo "INFO: Attempting to create root project '${TF_PROJECT_ID}' :"
gcloud projects create ${TF_PROJECT_ID} \
  --name="Root-level project Terraform Admin Project"
  --organization ${TF_VAR_org_id} \
  --set-as-default \
  --labels=level=0

echo "INFO: Linking root project '${TF_PROJECT_ID}' to billing account ${TF_VAR_billing_account}:"
gcloud alpha billing projects link ${TF_PROJECT_ID} \
  --billing-account ${TF_VAR_billing_account}

echo "INFO: Creating service account '${SERVICE_ACCOUNT}' for project ${TF_PROJECT_ID}:"
gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
  --display-name "Terraform admin account"

echo "INFO: Genarating new set of keys for service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com': "
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account ${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com

echo "INFO: Binding service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com' to IAM 'roles/viewer' : "
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/viewer

echo "INFO: Binding service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com' to IAM 'roles/storage.admin' : "
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/storage.admin


echo "INFO: Enabling service cloudresourcemanager.."
gcloud services enable cloudresourcemanager.googleapis.com
echo "INFO: Enabling service cloudbilling.."
gcloud services enable cloudbilling.googleapis.com
echo "INFO: Enabling service IAM.."
gcloud services enable iam.googleapis.com
echo "INFO: Enabling service compute.."
gcloud services enable compute.googleapis.com
echo "INFO: Enabling service sqladmin.."
gcloud services enable sqladmin.googleapis.com

# Part to setup terraform directories and backend env

mkdir -p terraform/test; cd terraform/test
# create backend bucket
gsutil mb -l ${TF_VAR_region} -p ${TF_PROJECT_ID} gs://${TF_PROJECT_ID}



# the end :)
