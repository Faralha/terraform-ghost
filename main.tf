# Configure Terraform Provider
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.25"
    }
  }
}

# --- NETWORK CONFIGURATION ---
resource "docker_network" "ghost_network" {
  name = "ghost_network"
}

# --- DATABASE CONFIGURATION ---
resource "docker_image" "mysql_image" {
  name         = "mysql:5.7"
  keep_locally = true
}

# Create MySQL Container
resource "docker_container" "mysql_container" {
  name  = "ghost-mysql"
  image = docker_image.mysql_image.name

  # Change native password authentication plugin to mysql_native_password + disable SSL
  command = ["mysqld", "--default-authentication-plugin=mysql_native_password", "--ssl=0"]

  # Environment variables for MySQL
  env = [
    "MYSQL_ROOT_PASSWORD=${var.database_password}",
    "MYSQL_DATABASE=${var.database_name}"
  ]

  # Ignore certain changes that don't affect functionality
  lifecycle {
    ignore_changes = [
      network_mode,
      entrypoint,
      hostname,
      ip_address,
      ip_prefix_length,
      gateway,
      network_data
    ]
  }

  # Port Allocation
  ports {
    internal = 3306
    external = 3306
  }

  networks_advanced {
    name = docker_network.ghost_network.name
  }
}

# --- GHOST CMS CONFIGURATION ---
resource "docker_image" "ghost_image" {
  name         = "ghost:${var.ghost_image_version}"
  keep_locally = true
}

# Create GhostCMS Container
resource "docker_container" "ghost_container" {
  name  = "ghost-cms"
  image = docker_image.ghost_image.name

  # Environment Variable for Ghost CMS
  env = [
    "database__client=mysql",
    "database__connection__host=ghost-mysql", # mysql container name
    "database__connection__user=root",
    "database__connection__password=${var.database_password}",
    "database__connection__database=${var.database_name}",
    "database__connection__port=3306",
    "database__connection__charset=utf8mb4",
    "url=${var.ghost_url}"
  ]

  # Ignore certain changes that don't affect functionality
  lifecycle {
    ignore_changes = [
      network_mode,
      command,
      entrypoint,
      hostname,
      ip_address,
      ip_prefix_length,
      gateway,
      network_data
    ]
  }

  # Healthcheck -> periodically check if Ghost is up and running
  healthcheck {
    test = ["CMD", "curl", "-f", var.ghost_url]
    interval = "1m"
    timeout = "10s"
    retries = 3
    start_period = "30s"
  }

  # Port to access Ghost from outside
  ports {
    internal = 2368
    external = 2368
  }

  # Create dependencies so ghost only starts after mysql ready
  depends_on = [ docker_container.mysql_container ]
  restart = "on-failure"
  networks_advanced {
    name = docker_network.ghost_network.name
  }
}

# Outputs Ghost URL after succesful deployment
output "ghost_url" {
  value = var.ghost_url
}