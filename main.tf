# Configure Terraform Provider
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# --- DATABASE CONFIGURATION ---
resource "docker_image" "mysql_image" {
  name         = "mysql:8.0"
  keep_locally = true
}

# Create MySQL Container
resource "docker_container" "mysql_container" {
  name  = "ghost_mysql"
  image = docker_image.mysql_image.name

  # Environment variables for MySQL
  env = [
    "MYSQL_ROOT_PASSWORD=${var.database_password}",
    "MYSQL_DATABASE=${var.database_name}"
  ]

  # Port Allocation
  ports {
    internal = 3306
    external = 3306
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
    "url=${var.ghost_url}"
  ]

  # Port to access Ghost from outside
  ports {
    internal = 2368
    external = 2368
  }

  # Create dependencies so ghost only starts after mysql ready
  depends_on = [ docker_container.mysql_container ]
}

# Outputs Ghost URL after succesful deployment
output "ghost_url" {
  value = var.ghost_url
}