
# vars

variable "name" {}
variable "project" {}
variable "auto_create_subnetworks" { default = "false" }
variable "ip_cidr_range" {}


# Create a standalone network with the same firewall rules.
resource "google_compute_network" "network" {
  name                    = "${var.name}"
  auto_create_subnetworks = "${var.auto_create_subnetworks}"
  project                 = "${var.project}"
  ipv4_range              = "${var.ip_cidr_range}"
#  depends_on              = ["google_project_service.standalone_project"]
}

# outputs
output "self_link" {
  value = "${google_compute_network.network.self_link}"
}

output "project" {
  value = "${var.project}"
}

output "name" {
  value = "${google_compute_network.network.name}"
}
