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


# Resources
# Create a VM which hosts a web page stating its identity ("VM1")
resource "google_compute_instance" "instance" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "f1-micro"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-8"
    }
  }
#  metadata_startup_script = "VM_NAME=VM1\n${file("../../modules/instance/compute/scripts/install-vm.sh")}"
  metadata {
    foo = "bar"
    VM_NAME="VM1"
  }
  metadata_startup_script = "${file("../../modules/instance/compute/scripts/install_vm.sh")}"
  network_interface {
    network = "${var.network}"
    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

//  depends_on = ["google_project_service.service_project_1"]
}


# Outputs
output "status_page_public_ip" {
  value = "${google_compute_instance.instance.network_interface.0.access_config.0.assigned_nat_ip}"
}
