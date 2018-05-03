#!/bin/bash

cd terraform/test

gsutil mb -l ${TF_VAR_region} -p ${TF_ADMIN} gs://${TF_ADMIN}

cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket = "${TF_ADMIN}"
   prefix  = "terraform/state/test"
 }
}
EOF

