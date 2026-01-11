variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region for resources"
  default     = "us-central1"
}

variable "zone" {
  description = "The zone for the VM"
  default     = "us-central1-a"
}

variable "db_user" {
  description = "The database user"
  default     = "admin"
}

variable "db_password" {
  description = "The database password"
  type        = string
  sensitive   = true
}
