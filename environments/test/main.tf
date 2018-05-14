# vars
variable "env" {
  default = ""
}
variable "region" {
}
variable "billing_account" {
}
variable "org_id" {
}
variable "credentials_file_path" {
  default = ""
}
variable "domain" {
}
variable "admin_project" {
}
variable "g_folder" {
  default = ""
}
variable "g_folder_id" {
  default = ""
}

# resources
#module "host_project" {
#  source          = "../../modules/project"
#  name            = "host-project"
#  region          = "${var.region}"
#  billing_account = "${var.billing_account}"
#  org_id          = "${var.org_id}"
#  domain = "${var.domain}"
#  create_folder = true
#}


module "service_1_project" {
  source          = "../../modules/project"
  name            = "service-prj-1-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain = "${var.domain}"
}

module "service_2_project" {
  source          = "../../modules/project"
  name            = "service-prj-2-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain = "${var.domain}"
}

resource "google_compute_shared_vpc_host_project" "host_project" {
  project    = "${var.admin_project}"
}

# Enable shared VPC in the two service projects and services need to be enabled on all new projects
# Service project #1
resource "google_project_service" "service_1_project" {
  project = "${module.service_1_project.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "service_1_project" {
  host_project    = "${var.admin_project}"
  service_project = "${module.service_1_project.project_id}"

  depends_on = [
    "module.service_1_project"
  ]
}

# Service project #2
resource "google_project_service" "service_2_project" {
  project = "${module.service_2_project.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "service_2_project" {
  host_project    = "${var.admin_project}"
  service_project = "${module.service_2_project.project_id}"

  depends_on = [
    "module.service_2_project"
  ]
}

# Create the hosted network.
resource "google_compute_network" "shared_network" {
  name                    = "shared-network"
  auto_create_subnetworks = "true"
  project                 = "${var.admin_project}"

  depends_on = [
    "module.service_1_project",
    "module.service_2_project"
  ]
}

# Allow the hosted network to be hit over ICMP, SSH, and HTTP.
resource "google_compute_firewall" "shared_network" {
  name    = "allow-ssh-and-icmp"
  network = "${google_compute_network.shared_network.self_link}"
  project = "${google_compute_network.shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }
}


##
