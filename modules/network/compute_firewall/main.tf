
resource "google_compute_firewall" "standalone_network" {
  name    = "allow-ssh-and-icmp"
  network = "${google_compute_network.standalone_network.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  project = "${google_project.standalone_project.project_id}"
}

