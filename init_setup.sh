#!/bin/bash -e

export GCPfile=$1

SERVICE_ACCOUNT=terraform

if [ -f $GCPfile ]; then
   . ${GCPfile}
else
  echo "File doesn't exist: " ${GCPfile}
  exit 1
fi

## TODO: check all required variables..
# gcloud config set account $GOOGLE_ADMIN_ACCOUNT

echo "INFO: Listing organizations:"
gcloud beta organizations list

echo "INFO: Listing billing accounts:"
gcloud alpha billing accounts list

RANDOMID=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 8 ; echo)
TF_PROJECT_ID="${TF_ADMIN}-${TF_ENV}-${RANDOMID}"

echo "INFO: Checking if folder named ${TF_FOLDER} exists.. please stand by.. "
#FOLDERS=$(gcloud alpha resource-manager folders list --organization ${TF_VAR_org_id} --format json | jq '.[] | .displayName')
#FOLDER_CHECK=$(gcloud alpha resource-manager folders list --organization ${TF_VAR_org_id} --format json | jq '.[] | .displayName' | grep ${TF_FOLDER} )
FULL_FOLDER_ID=$(gcloud alpha resource-manager folders list --organization ${TF_VAR_org_id} --format json | jq -r --arg TF_FOLDER "$TF_FOLDER" '.[] | select(.displayName==$TF_FOLDER ) | .name')

if [[ ! -z "${FULL_FOLDER_ID}" ]]; then
  echo "INFO: Folder '${TF_FOLDER}' with ID ${FULL_FOLDER_ID} already exist as part of the org '${TF_VAR_org_id}' :"
else
  echo "INFO: Attempting to create folder '${TF_FOLDER}' for the org '${TF_VAR_org_id}' :"
  FULL_FOLDER_ID=$(gcloud alpha resource-manager folders create \
     --display-name=${TF_FOLDER} \
     --organization ${TF_VAR_org_id} \
     --format="value(name)")
fi


FOLDER_ID=$(echo $FULL_FOLDER_ID | sed 's/folders\///')
echo "INFO: Folder ID: ${FOLDER_ID} "
echo $FULL_FOLDER_ID > /tmp/full_folder.id

echo "INFO: Attempting to create admin project '${TF_PROJECT_ID}' :"
gcloud projects create ${TF_PROJECT_ID} \
  --set-as-default \
  --labels=level=0 \
  --folder=${FOLDER_ID}
echo $${TF_PROJECT_ID}  > /tmp/tf_project.id

# this is leftover, TODO
ret_code="$?"
if [ ret_code == 0 ]; then
  echo "ERROR: return code: " $ret_code
  exit 1
fi

echo "INFO: Linking root project '${TF_PROJECT_ID}' to billing account ${TF_VAR_billing_account}:"
gcloud alpha billing projects link ${TF_PROJECT_ID} \
  --billing-account ${TF_VAR_billing_account}

echo "INFO: Creating service account '${SERVICE_ACCOUNT}' for project ${TF_PROJECT_ID}:"
gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
  --display-name "Terraform admin service account"

echo "INFO: Genarating new set of keys for service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com': "
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account ${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com

echo "INFO: Binding service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com' to IAM 'roles/resourcemanager.folderAdmin' for folder ${FOLDER_ID} : "
gcloud alpha resource-manager folders add-iam-policy-binding ${FOLDER_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/resourcemanager.folderAdmin

echo "INFO: Binding service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com' to IAM 'roles/viewer' : "
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/editor

# gcloud auth activate-service-account --key-file=${TF_CREDS}

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

# Activate Terraform service account
# gcloud auth activate-service-account --key-file=${TF_CREDS}

# Part to setup terraform directories and backend env

# create backend bucket
echo "gsutil mb -l ${TF_VAR_region} -p ${TF_PROJECT_ID} gs://${TF_PROJECT_ID}"

gsutil mb -l ${TF_VAR_region} -p ${TF_PROJECT_ID} gs://${TF_PROJECT_ID}

gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com:objectCreator,objectViewer  gs://${TF_PROJECT_ID}

#gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
#  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
#  --role roles/storage.objects.list
#
#gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
#  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
#  --role roles/storage.buckets.insert

echo "INFO: Binding service account '${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com' to IAM 'roles/storage.admin' : "
gcloud projects add-iam-policy-binding ${TF_PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT}@${TF_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/storage.admin

# set proper vars for TF init
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=${TF_PROJECT_ID}


# change directory
mkdir -p environments/$TF_ENV
cd environments/$TF_ENV

# generate backend TF file
cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket = "${TF_PROJECT_ID}"
   prefix  = "terraform/state/${TF_ENV}"
 }
}
EOF

# get ip of this machine
ALLOWED_IP_RANGE=$(curl ifconfig.co)
# generate TFVARS file for Terraform project
cat << EOF > $TF_ENV.tfvars
env = "$TF_ENV"
region = "$GOOGLE_REGION"
billing_account = "$TF_VAR_billing_account"
org_id = "$TF_VAR_org_id"
domain = "$GOOGLE_ADMIN_DOMAIN"
admin_account="$GOOGLE_ADMIN_ACCOUNT"
g_folder = "$FULL_FOLDER_ID"
g_folder_id = "$FOLDER_ID"
admin_project = "$TF_PROJECT_ID"
source_ranges_ips = "$ALLOWED_IP_RANGE/32"
tf_ssh_key = "$TF_VAR_ssh_key"
tf_ssh_private_key_file = "$TF_VAR_ssh_private_key"
EOF

# ...and run TF init
#terraform init

# ...followed by TF plan
#terraform plan

# clean up
#gcloud auth login --activate ${GOOGLE_ADMIN_ACCOUNT}

# the end :)
