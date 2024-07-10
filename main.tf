locals {
  db_map_raw   = split(";", data.aws_ssm_parameter.db_connection_string.value)
  db_map_clear = nonsensitive(local.db_map_raw)
  db_map       = { for param in local.db_map_clear : split("=", param)[0] => split("=", param)[1] }
  db_schemas   = data.postgresql_schemas.db_schemas.schemas
}

data "aws_ssm_parameter" "db_connection_string" {
  name = var.db_connection_string_path
}

data "postgresql_schemas" "db_schemas" {
  database = local.db_map["Database"]
}


########################################################################
# Create DB read only role and users
########################################################################

resource "postgresql_role" "read_only_role" {
  name  = var.read_only_role_name
  login = false
}

# Create users and assign to read only role
resource "postgresql_role" "read_only_user" {
  for_each        = var.read_only_user_credentials
  name            = each.value.username
  password        = each.value.password
  login           = true
  superuser       = false
  create_database = false
  create_role     = false
  inherit         = true
  replication     = false
  roles           = [postgresql_role.read_only_role.name]
}

# Grant read only role SELECT on schema
resource "postgresql_grant" "read_only_grant" {
  for_each    = toset(local.db_schemas)
  database    = local.db_map["Database"]
  role        = postgresql_role.read_only_role.name
  schema      = each.value
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "read_only_sequence_privileges" {
  for_each    = toset(local.db_schemas)
  database    = local.db_map["Database"]
  role        = postgresql_role.read_only_role.name
  schema      = each.value
  object_type = "sequence"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.read_only_role]
}

resource "postgresql_grant" "read_only_schema_privileges" {
  for_each    = toset(local.db_schemas)
  database    = local.db_map["Database"]
  role        = postgresql_role.read_only_role.name
  schema      = each.value
  object_type = "schema"
  privileges  = ["USAGE"]
  depends_on  = [postgresql_role.read_only_role]
}

resource "postgresql_default_privileges" "read_only_table_default_privileges" {
  for_each    = toset(local.db_schemas)
  database    = local.db_map["Database"]
  owner       = local.db_map["Username"]
  role        = postgresql_role.read_only_role.name
  schema      = each.value
  object_type = "table"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.read_only_role]
}

resource "postgresql_default_privileges" "read_only_sequence_default_privileges" {
  for_each    = toset(local.db_schemas)
  database    = local.db_map["Database"]
  owner       = local.db_map["Username"]
  role        = postgresql_role.read_only_role.name
  schema      = each.value
  object_type = "sequence"
  privileges  = ["SELECT"]
  depends_on  = [postgresql_role.read_only_role]
}


########################################################################
# Create DB admin role and users
########################################################################

resource "postgresql_role" "admin_role" {
  count = length(var.admin_user_credentials) > 0 ? 1 : 0
  name  = var.admin_role_name
  login = false

  lifecycle {
    ignore_changes = [
      roles,
    ]
  }
}

resource "postgresql_role" "admin_user" {
  for_each        = var.admin_user_credentials
  name            = each.value.username
  password        = each.value.password
  login           = true
  superuser       = false
  create_database = false
  create_role     = false
  inherit         = true
  replication     = false
  roles           = [postgresql_role.admin_role[0].name]
}

resource "postgresql_grant_role" "grant_root" {
  count      = length(var.admin_user_credentials) > 0 ? 1 : 0
  role       = postgresql_role.admin_role[0].name
  grant_role = "rds_superuser"
}

# resource "postgresql_grant" "admin_grant_table" {
#   for_each    = { for schema in local.db_schemas : schema => schema if length(var.admin_user_credentials) > 0 }
#   database    = local.db_map["Database"]
#   role        = postgresql_role.admin_role[0].name
#   schema      = each.value
#   object_type = "table"
#   privileges  = ["SELECT", "DELETE", "INSERT", "UPDATE"]
# }

# resource "postgresql_grant" "admin_grant_sequence_privileges" {
#   for_each    = { for schema in local.db_schemas : schema => schema if length(var.admin_user_credentials) > 0 }
#   database    = local.db_map["Database"]
#   role        = postgresql_role.admin_role[0].name
#   schema      = each.value
#   object_type = "sequence"
#   privileges  = ["USAGE", "SELECT", "UPDATE"]
# }

# resource "postgresql_grant" "admin_grant_schema_privileges" {
#   for_each    = { for schema in local.db_schemas : schema => schema if length(var.admin_user_credentials) > 0 }
#   database    = local.db_map["Database"]
#   role        = postgresql_role.admin_role[0].name
#   schema      = each.value
#   object_type = "schema"
#   privileges  = ["USAGE"]
# }

# resource "postgresql_default_privileges" "admin_table_default_privileges" {
#   for_each    = { for schema in local.db_schemas : schema => schema if length(var.admin_user_credentials) > 0 }
#   database    = local.db_map["Database"]
#   owner       = local.db_map["Username"]
#   role        = postgresql_role.admin_role[0].name
#   schema      = each.value
#   object_type = "table"
#   privileges  = ["SELECT", "DELETE", "INSERT", "UPDATE"]
# }

# resource "postgresql_default_privileges" "admin_sequence_default_privileges" {
#   for_each    = { for schema in local.db_schemas : schema => schema if length(var.admin_user_credentials) > 0 }
#   database    = local.db_map["Database"]
#   owner       = local.db_map["Username"]
#   role        = postgresql_role.admin_role[0].name
#   schema      = each.value
#   object_type = "sequence"
#   privileges  = ["USAGE", "SELECT", "UPDATE"]
# }
