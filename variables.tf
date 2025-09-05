variable "ghost_image_version" {
  description = "Version of Docker image for Ghost CMS"
  type = string
  default = "5.130-alpine"
}

variable "database_password" {
  description = "Password for the Ghost CMS database user"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the database for Ghost CMS"
  type        = string
  default     = "ghost_db"
}

variable "ghost_url" {
  description = "URL where the Ghost CMS will be accessible"
  type        = string
  default     = "http://localhost:2368"
}