terraform {
  required_version = ">= 1.0"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

provider "postgresql" {
  host            = local.db_map["Host"]
  port            = local.db_map["Port"]
  database        = local.db_map["Database"]
  username        = local.db_map["Username"]
  password        = local.db_map["Password"]
  sslmode         = var.db_ssl_mode
  connect_timeout = 15
  superuser       = false
}
