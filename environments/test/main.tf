# vars
variable "env" {
  default = "test"
}
variable "region" {
  default = "northamerica-northeast1"
}
variable "billing_account" {
  default = "your-billing-act"
}
variable "org_id" {
  default = "your-org-id"
}
variable "credentials_file_path" {
  default = ""
}

# resources
module "project" {
  source          = "../../modules/project"
  name            = "test-project-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "1070281113360"
#  credentials_file_path = "${var.credentials_file_path}"
  folder = "dev_test_projects"
}
