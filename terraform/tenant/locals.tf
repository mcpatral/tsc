locals {
  name_base                            = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash                    = replace(local.name_base, "-", "")
  provider_default_storage_use_azuread = true
  provider_sas_storage_use_azuread     = false

  remote_state = {
    resource_group_name  = "rg-${local.name_base}-state"
    storage_account_name = "sa${local.name_base_no_dash}tfstate"
    container_name       = "${var.ENVIRONMENT_TYPE}tfstate"
    use_azuread_auth     = true
  }

  postgresql = {
    database_name = "airflow${var.TENANT_NAME}"
    server_id     = data.terraform_remote_state.infrastructure.outputs.psql_server_id
    collation     = "en_US.utf8"
    charset       = "utf8"
  }

  storage_account = {
    objects = {
      "dl" = {
        shared_access_key_enabled = false
        containers = {
          "landing${var.TENANT_NAME}" = {
            include_in_management_policy = true
            directories = {
              "cff1_files"     = {
                acls = {                  
                  txbobjectid         = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "cff2_files"     = {
                acls = {                  
                  txbobjectid         = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "currency_rates" = {
                acls = {                  
                  txbobjectid         = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "error_files"    = {}
            }
          }
        }
      }
      "airflow" = {
        shared_access_key_enabled = true
        containers = {
          "dags${var.TENANT_NAME}" = {
            include_in_management_policy = false
            directories                  = {}
          }
          "logs${var.TENANT_NAME}" = {
            include_in_management_policy = true
            directories                  = {}
          }
        }
      }
    }
  }
}