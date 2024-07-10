output "db_schemas" {
  description = "List of database schemas"
  value       = data.postgresql_schemas.db_schemas.schemas
}
