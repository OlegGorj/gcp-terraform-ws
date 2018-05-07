
# Vars
variable "name" {}
variable "project" {}
variable "zones" { type = "list" }
variable "subnet_name" {}
variable "image" {}
variable "instance_type" {}
variable "user" {}
variable "ssh_key" {}

# main.tf
resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnet_name}"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  tags = ["bastion"]
}

# Outputs

output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}

