
# Vars
variable "name" {}
variable "project" {}
variable "zones" { type = "list" }
variable "subnet_name" {}
#variable "image" {}
variable "instance_type" {
  default = "f1-micro"
}

variable "ssh_user" {}
variable "ssh_key" {}
varibale "ssh_private_key_file" {}

variable "environment" {
  default = ""
}
variable "instance_description" {
  default = "Bastion instance"
}

data "google_compute_image" "cos_cloud" {
  family = "cos-stable"
  project = "cos-cloud"
}

# main.tf
resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  metadata {
    ssh-keys = "${var.ssh_user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.cos_cloud.self_link}"
    }
  }
#  boot_disk {
#    initialize_params {
#      image = "${var.image}"
#    }
#  }

  network_interface {
    subnetwork = "${var.subnet_name}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  service_account {
     scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  metadata {
    mastercount = "${var.masters}"
    clustername = "${var.name}"
    myid = "${count.index}"
    domain = "${var.domain}"
    subnetwork = "${var.subnetwork}"
    mesosversion = "${var.mesos_version}"
  }
  # define default connection for remote provisioners
  connection {
    type = "ssh"
    user = "${var.ssh_user}"
    private_key = "${file(var.ssh_private_key_file)}"
  }
  tags = ["bastion", "vpn"]
}

# Outputs

output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}
