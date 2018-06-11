# vars
variable "env" {
}
variable "region" {
}
variable "region_zone" {
}
variable "billing_account" {
}
variable "org_id" {
}
variable "credentials_file_path" {
  default = ""
}
variable "tf_ssh_key" {
  default = ""
}
variable "tf_ssh_private_key_file"{
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
variable "source_ranges_ips" {
  default = ""
}
variable "devops_subnet1_northamerica_northeast1_cidr" {
  default = "10.0.0.0/16"
}

###############################################################################
# RESOURCES
###############################################################################

module "devops_project_1" {
  source          = "../../modules/project"
  name            = "service-prj-1-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain          = "${var.domain}"
}

module "devops_project_2" {
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
resource "google_project_service" "devops_project_1" {
  project = "${module.devops_project_1.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "devops_project_1" {
  host_project    = "${var.admin_project}"
  service_project = "${module.devops_project_1.project_id}"

  depends_on = [
    "module.devops_project_1"
  ]
}

# Service project #2
resource "google_project_service" "devops_project_2" {
  project = "${module.devops_project_2.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "devops_project_2" {
  host_project    = "${var.admin_project}"
  service_project = "${module.devops_project_2.project_id}"

  depends_on = [
    "module.devops_project_2"
  ]
}

# Create the hosted network.
#resource "google_compute_network" "devops_shared_network" {
#  name                    = "devops-compute-network"
#  auto_create_subnetworks = "false"
#  project                 = "${var.admin_project}"
#
#  depends_on = [
#    "module.devops_project_1",
#    "module.devops_project_2"
#  ]
#}

module "devops_shared_network" {
  source                    = "../../modules/network/compute_network"
  name                      = "devops-shared-network"
  project                   = "${var.admin_project}"
  auto_create_subnetworks   = "false"
}

module "devops_subnet_northamerica_northeast1" {
  source          = "../../modules/network/subnet"
  name            = "devops-subnet-1"
  project         = "${var.admin_project}"
  region          = "northamerica-northeast1"
  network         = "${module.devops_shared_network.self_link}"
  ip_cidr_range   = "${var.devops_subnet1_northamerica_northeast1_cidr}"
}



# Allow access DevOPS network only bastion instances  and limited source range
resource "google_compute_firewall" "devops_network_ssh_bastion_fw" {
  name    = "allow-ssh-icmp-http-devops_shared_network"
  network = "${module.devops_shared_network.self_link}"
  project = "${module.devops_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${var.source_ranges_ips}"]

  target_tags = ["bastion"]
}

resource "google_compute_firewall" "devops_network_https_bastion_fw" {
  name    = "allow-ssh-icmp-http-devops_shared_network"
  network = "${module.devops_shared_network.self_link}"
  project = "${module.devops_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "80", "8080", "8443"]
  }

  source_ranges = ["${var.source_ranges_ips}"]

  target_tags = ["bastion"]
}

# TODO: Internal Communication fw



module "bastion_instance" {
  source                = "../../modules/network/bastion"
  name                  = "bastion-instance"
  project               = "${module.devops_project_1.project_id}"
  zones                 = ["${var.region_zone}"]
  subnetwork           = "${module.devops_subnet_northamerica_northeast1.self_link}"
  ssh_user              = "ubuntu"
  ssh_key               = "${var.tf_ssh_key}"
  ssh_private_key_file  = "${var.tf_ssh_private_key_file}"
  environment           = "${var.env}"
  domain    = "${var.domain}"
}

# TODO: fw rules to allow ssh access to other instances only from bastion


# Create VM instances for each project
# Instance #1
module "devops_instance_vm1" {
  source                = "../../modules/instance/compute"
  name                  = "devops-instance-vm1"
  project               = "${module.devops_project_1.project_id}"
  zone                  = "${var.region_zone}"
  network               = "${module.devops_shared_network.self_link}"
  startup_script        = "VM_NAME=VM1\n${file("../../modules/instance/compute/scripts/install_vm.sh")}"
  instance_tags         = ["devops", "debian-8", "${var.env}", "apache2"]
  environment           = "${var.env}"
  instance_description  = "VM Instance dedicated to Devops"
}

# Instance #2 - ngnix on docker
data "template_file" "docker_init_script" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_file" "ngnix_init_script" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_file" "ngnix_init_cc_config" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.yml")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_cloudinit_config" "webserver_init" {
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ngnix_init_script.rendered}"
  }
}
data "template_cloudinit_config" "ngnix_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "ngnix_install.yml"
    content_type = "text/cloud-config"
    content    = "${data.template_file.ngnix_init_cc_config.rendered}"
  }
}
module "devops_instance_vm2" {
  source                = "../../modules/instance/compute"
  name                  = "devops-instance-vm2"
  project               = "${module.devops_project_2.project_id}"
  zone                  = "${var.region_zone}"
  network               = "${module.devops_shared_network.self_link}"
#  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
#  startup_script        = "${data.template_cloudinit_config.ngnix_init.rendered}"
  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
  instance_tags         = ["devops", "ngnix", "ubuntu-1604", "${var.env}", "docker"]
  environment           = "${var.env}"
  instance_description  = "VM Instance dedicated to Devops"
}


##
