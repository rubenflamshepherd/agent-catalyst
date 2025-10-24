// ABOUTME: Creates networking resources for the infrastructure.
// ABOUTME: Provisions VPC network for resource connectivity.

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
