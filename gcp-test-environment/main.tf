terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.39.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "network" {
  name                    = "kubeadm-test"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_firewall" "allow_tcp_icmp" {
  name    = "allow-tcp-icmp"
  network = google_compute_network.network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_subnetwork" "subnetwork" {
  network       = google_compute_network.network.name
  name          = "${google_compute_network.network.name}-subnet"
  ip_cidr_range = "10.10.10.0/24"
}

resource "google_compute_router" "nat_router" {
  name    = "kubeadm-test-nat-router"
  network = google_compute_network.network.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "kubeadm-test-nat-config"
  router                             = google_compute_router.nat_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_instance_template" "template" {
  name         = "kubeadm-test-instance"
  # custom VM with 2vCPU, 3 GB of RAM:
  machine_type = "n2d-custom-2-3072"

  network_interface {
    network    = google_compute_network.network.name
    subnetwork = google_compute_subnetwork.subnetwork.name
  }


  disk {
    source_image = "ubuntu-os-cloud/ubuntu-minimal-2004-lts"
  }

  metadata = {
    ssh-keys = "ansible:${file("ansible_key.pub")}"
  }

  can_ip_forward = true
}

resource "google_compute_instance_from_template" "controllers" {
  source_instance_template = google_compute_instance_template.template.id
  count = 3
  name  = format("%s%s", "controller-", count.index)
}

resource "google_compute_instance_from_template" "workers" {
  source_instance_template = google_compute_instance_template.template.id
  count = 1
  name  = format("%s%s", "worker-", count.index)
}

resource "google_compute_instance" "ansible_controller" {
  name         = "ansible-controller"
  machine_type = "n2d-custom-2-1024"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.network.name
    subnetwork = google_compute_subnetwork.subnetwork.name
  }

  metadata_startup_script = file("startup.sh")
}
