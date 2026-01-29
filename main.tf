terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    prefix = "terraform/state"
    # bucket is configured via -backend-config in CI/CD
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable APIs
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name       = "terraform-network"
  depends_on = [google_project_service.compute_api]
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = "terraform-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall for HTTP/SSH
resource "google_compute_firewall" "default" {
  name    = "allow-http-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "5000"] # 5000 for Flask
  }

  source_ranges = ["0.0.0.0/0"]
}

# Cloud SQL Instance
resource "google_sql_database_instance" "master" {
  name                = "ping-pong-mysql-instance-${random_id.db_name_suffix.hex}"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false # For demo purposes

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      # Disable public IPv4 to avoid exposing the instance to the internet.
      ipv4_enabled = false
      # For private access prefer Private IP (Private Services Access / VPC peering)
      # and/or use the Cloud SQL Proxy for secure connections.
      # To enable Private IP, configure a `google_compute_global_address` for
      # private services access and a `google_service_networking_connection`,
      # then set `private_network = google_compute_network.vpc_network.self_link`.
      # Example (TODO):
      # private_network = google_compute_network.vpc_network.self_link
      require_ssl = true
    }
  }
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Database
resource "google_sql_database" "database" {
  name     = "pingpongdb"
  instance = google_sql_database_instance.master.name
}

# User
resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.master.name
  password = var.db_password
}

# Compute Instance
resource "google_compute_instance" "vm_instance" {
  name         = "ping-pong-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y python3-pip"

  tags = ["http-server"]

  lifecycle {
    prevent_destroy = true
  }
}
