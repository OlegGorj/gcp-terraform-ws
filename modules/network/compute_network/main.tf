

# Create a standalone network with the same firewall rules.
resource "google_compute_network" "standalone_network" {
  name                    = "standalone-network"
  auto_create_subnetworks = "true"
  project                 = "${google_project.standalone_project.project_id}"
  depends_on              = ["google_project_service.standalone_project"]
}


