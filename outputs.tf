output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "db_connection_name" {
  value = google_sql_database_instance.master.connection_name
}

# Removed public IP output to avoid exposing Cloud SQL public address when
# the instance is configured without a public IPv4. Use `db_connection_name`
# (connection_name) or configure private IP outputs when Private Services
# Access is enabled.
