terraform {
  backend "gcs" {
    bucket = "agent-catalyst-c405ad20-terraform-state"
    prefix = "agent-catalyst/terraform/state"
  }
}
