# Vars
variable "name" {}
variable "project" {}
variable "machine_type" {
  default = "f1-micro"
}
variable "zone" {
  default = ""
}
variable "network" {
}
variable "instance_tags" {
  type = "list"
  default = [""]
}
variable "environment" {
  default = ""
}
variable "startup_script" {
  default = ""
}
variable "automatic_restart" {
  default = true
}
variable "instance_description" {
  default = "Default instance description"
}

# Resources
# Create a VM which hosts a web page stating its identity ("VM1")
#data "google_compute_image" "ubuntu-xenial" {
#  family = "ubuntu-1604-lts"
#  project = "ubuntu-os-cloud"
#}
resource "google_compute_instance" "instance" {
  description = "description assigned to instances"

  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      #image = "projects/debian-cloud/global/images/family/debian-8"
      #image = "${data.google_compute_image.ubuntu.self_link}"
      image = "ubuntu-1604-lts"
    }
  }
#  metadata_startup_script = "VM_NAME=VM1\n${file("../../modules/instance/compute/scripts/install-vm.sh")}"
  metadata_startup_script = "${var.startup_script}"
  network_interface {
    network = "${var.network}"
    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly", "storage-ro"]
  }

  metadata {
    sshKeys = "ubuntu:${file("~/.ssh/dev_key.pub")}"
  }

  labels {
    environment   = "${var.environment}"
    machine_type  = "${var.machine_type}"
  }

  tags = "${var.instance_tags}"

  scheduling {
    automatic_restart   = "${var.automatic_restart}"
    on_host_maintenance = "MIGRATE"
  }
}


# Outputs

output "status_page_public_ip" {
  value = "${google_compute_instance.instance.network_interface.0.access_config.0.assigned_nat_ip}"
}
