terraform {
 backend "gcs" {
   bucket = "tf-admin-8unykipkc"
   prefix  = "terraform/state/test"
 }
}
