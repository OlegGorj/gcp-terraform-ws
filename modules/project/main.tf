# vars
variable "name" {}
variable "region" {}
variable "billing_account" {}
variable "org_id" {}
#variable "credentials_file_path" {}
variable "folder" {}

# resources
provider "google" {
  region = "${var.region}"
#  credentials = "${file("${var.credentials_file_path}")}"
}

data "google_organization" "org-name" {
  domain = "org-name.cloud"
}
output "org_id" {
  value = "${data.google_organization.org-name.id}"
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "${var.name}-"
}

resource "google_folder" "folder" {
  display_name = "${var.folder}"
  parent       = "organizations/${var.org_id}"
}

resource "google_project" "project" {
  name            = "${var.name}"
  project_id      = "${random_id.id.hex}"
  billing_account = "${var.billing_account}"
  folder_id       = "${google_folder.folder.id}"
}

resource "google_project_services" "project" {
 project = "${google_project.project.project_id}"
 services = [
   "compute.googleapis.com",
   "sqladmin.googleapis.com"
 ]
}

# outputs
output "id" {
  value = "${google_project.project.id}"
}

output "name" {
  value = "${google_project.project.name}"
}

output "folder-name" {
  value = "${google_folder.folder.name}"
}
