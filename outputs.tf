output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "db_connection_name" {
  value = google_sql_database_instance.master.connection_name
}

output "db_public_ip" {
  value = google_sql_database_instance.master.public_ip_address
}
