# PostgreSQL user management module

## About

This module creates read_only_role and assign users to it. It also generates random passwords for the read_only users and stores them in AWS SSM Parameter Store.

## Usage

```tf
locals {
  read_only_users = [
    "user1",
    "user2"
  ]

  admin_users = [
    "user1_admin"
  ]

  all_users = concat(local.read_only_users, local.admin_users)

  all_user_credentials = merge(
    {for user, credentials in local.read_only_user_credentials : user => credentials},
    {for user, credentials in local.admin_user_credentials : user => credentials}
  )

  read_only_user_credentials = {
    for user in local.read_only_users :
    user => {
      username = user
      password = random_password.user_passwords[user].result
    }
  }

  admin_user_credentials = {
    for user in local.admin_users :
    user => {
      username = user
      password = random_password.user_passwords[user].result
    }
  }

  kms_key_alias = "${terraform.workspace}-ssm"
}

data "aws_kms_alias" "ssm" {
  name = "alias/${local.kms_key_alias}"
}

data "aws_kms_key" "ssm" {
  key_id = data.aws_kms_alias.ssm.arn
}

resource "random_password" "user_passwords" {
  for_each         = toset(local.all_users)
  length           = 16
  special          = false
  min_upper        = 2
  min_numeric      = 2

  keepers = {
    keeper1 = var.user_passwords_trigger
  }
}

resource "aws_ssm_parameter" "read_only_user_credentials" {
  name   = "/${terraform.workspace}/db_user_credentials"
  type   = "SecureString"
  value  = jsonencode(local.all_user_credentials)
  key_id = data.aws_kms_key.ssm.arn
}


module "mydb" {
  source = "git@github.com:credis-uk/terraform-modules.git//aws/postgresql?ref=main"

  db_connection_string_path  = "/${terraform.workspace}/backend/DbConnectionString"
  read_only_user_credentials = local.read_only_user_credentials
  admin_user_credentials = local.admin_user_credentials
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | => 3.0 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | ~> 1.21.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | => 3.0 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | ~> 1.21.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [postgresql_default_privileges.read_only_sequence_default_privileges](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/default_privileges) | resource |
| [postgresql_default_privileges.read_only_table_default_privileges](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/default_privileges) | resource |
| [postgresql_grant.read_only_grant](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant.read_only_schema_privileges](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant.read_only_sequence_privileges](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_role.read_only_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.read_only_user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [aws_ssm_parameter.db_connection_string](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [postgresql_schemas.db_schemas](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/data-sources/schemas) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_connection_string_path"></a> [db\_connection\_string\_path](#input\_db\_connection\_string\_path) | Postgresql read only user | `string` | `""` | no |
| <a name="input_db_ssl_mode"></a> [db\_ssl\_mode](#input\_db\_ssl\_mode) | Postgresql database owner user name | `string` | `"require"` | no |
| <a name="input_read_only_role_name"></a> [read\_only\_role\_name](#input\_read\_only\_role\_name) | Postgresql read only role name | `string` | `"read_only_access"` | no |
| <a name="input_read_only_user_credentials"></a> [read\_only\_user\_credentials](#input\_read\_only\_user\_credentials) | Postgresql map with read only users and passwords | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_schemas"></a> [db\_schemas](#output\_db\_schemas) | List of database schemas |
