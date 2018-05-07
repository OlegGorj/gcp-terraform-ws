
# variables

variable "org_id" {}
#variable "credentials_file_path" {}
variable "folder" {}


resource "google_folder" "folder" {
  display_name = "${var.folder}"
  parent       = "${var.org_id}"
}

# outputs
output "folder-name" {
  value = "${google_folder.folder.name}"
}

