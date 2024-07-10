variable "read_only_role_name" {
  description = "Postgresql read only role name"
  type        = string
  default     = "read_only_access"
}

variable "admin_role_name" {
  description = "Postgresql admin role name"
  type        = string
  default     = "admin_role"
}

variable "read_only_user_credentials" {
  description = "Postgresql map with read only users and passwords"
  type        = map(any)
  default     = {}
}

variable "admin_user_credentials" {
  description = "Postgresql map with admin users and passwords"
  type        = map(any)
  default     = {}
}

variable "db_connection_string_path" {
  description = "Postgresql read only user"
  type        = string
  default     = ""
}

variable "db_ssl_mode" {
  description = "Postgresql database owner user name"
  type        = string
  default     = "require"
}
