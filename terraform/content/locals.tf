locals {
  name_base         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash = replace(local.name_base, "-", "")

  backend_rg_name        = "rg-${local.name_base}-state"
  backend_sa_name        = "sa${local.name_base_no_dash}tfstate"
  backend_container_name = "${var.ENVIRONMENT_TYPE}tfstate"
  storage_use_azuread    = true
  use_azuread_auth       = true

  db_workspace_host   = data.terraform_remote_state.infrastructure.outputs.db_workspace_host
  db_workspace_id     = data.terraform_remote_state.infrastructure.outputs.db_workspace_id
  databricks_id       = data.terraform_remote_state.infrastructure.outputs.databricks_id
  db_access_connector = data.terraform_remote_state.infrastructure.outputs.access_connector_id["dbac-${local.name_base}-extloc"]

  silver_schemas   = toset(split(",", var.DATABRICKS_SCHEMAS))
  silver_groups    = toset(split(",", var.DATABRICKS_GROUP_SUFFIX))
  silver_group_ids = toset(split(",", var.DATABRICKS_GROUP_IDS))

  external_locations = {
    "sa${local.name_base_no_dash}dl" = {
      sa_name        = "sa${local.name_base_no_dash}dl"
      container_name = "silver"
    }
    "sa${local.name_base_no_dash}dl_bronze" = {
      sa_name        = "sa${local.name_base_no_dash}dl"
      container_name = "bronze"
    }
    "sa${local.name_base_no_dash}temp" = {
      sa_name        = "sa${local.name_base_no_dash}temp"
      container_name = "temporary"
    }
  }

  container_name = "silver"
  dl_name        = "sa${local.name_base_no_dash}dl"
  catalog_name   = "${var.ENVIRONMENT_TYPE}_${local.container_name}"

  airflow_spn_permissions = toset(["USE_CATALOG", "USE_SCHEMA", "MODIFY", "READ_VOLUME", "SELECT", "WRITE_VOLUME"])
  admin_spn_permissions   = toset(["USE_CATALOG", "USE_SCHEMA", "MODIFY", "READ_VOLUME", "SELECT", "WRITE_VOLUME"])

  databricks_currency_table_name         = "currency_rates"
  databricks_currency_table_type         = "EXTERNAL"
  databricks_currency_data_source_format = "DELTA"
  databricks_currency_storage_location   = "abfss://${local.container_name}@${local.dl_name}.dfs.core.windows.net/lookup/currency_rates"

  secret_scope_name         = "kv-main-scope"
  secret_key_vault_id       = data.terraform_remote_state.infrastructure.outputs.key_vault_id["main"]
  secret_key_vault_dns_name = data.terraform_remote_state.infrastructure.outputs.key_vault_uri["main"]

  clusters = {
    "single" = {
      node_type_id            = var.SINGLE_DATABRICKS_CLUSTERSIZE
      driver_node_type_id     = var.SINGLE_DATABRICKS_CLUSTERSIZE_DRIVER
      autotermination_minutes = 30
      data_security_mode      = "SINGLE_USER"
      spnclientid             = var.airflowdbwspclientid
      #databricks_cluster autoscale
      min_workers = 0
      max_workers = 4
      #databricks_cluster spark_conf
      spark_databricks_io_cache_enabled          = true
      spark_databricks_io_cache_maxDiskUsage     = "16g"
      spark_databricks_io_cache_maxMetaDataCache = "1g"
      spark_databricks_delta_preview_enabled     = true
      spark_databricks_aggressiveWindowDownS     = 300
      #databricks_cluster spark_env_vars
      spark_databricks_pyspark_python = "/databricks/python3/bin/python3"
      #databricks_cluster azure_attributes
      availability          = var.DATABRICKS_CLUSTER_AVAILABILITY
      first_on_demand       = 1
      spot_bid_max_price    = -1
      python_package        = "dacite==1.6.0"
      init_script_workspace = "/Shared/init_packages.sh"
    }
    "provision" = {
      node_type_id            = var.PROVISION_DATABRICKS_CLUSTERSIZE
      driver_node_type_id     = var.PROVISION_DATABRICKS_CLUSTERSIZE_DRIVER
      autotermination_minutes = 30
      data_security_mode      = "SINGLE_USER"
      spnclientid             = data.azurerm_client_config.current.client_id
      #databricks_cluster autoscale
      min_workers = 0
      max_workers = 4
      #databricks_cluster spark_conf
      spark_databricks_io_cache_enabled          = true
      spark_databricks_io_cache_maxDiskUsage     = "16g"
      spark_databricks_io_cache_maxMetaDataCache = "1g"
      spark_databricks_delta_preview_enabled     = true
      spark_databricks_aggressiveWindowDownS     = 40
      #databricks_cluster spark_env_vars
      spark_databricks_pyspark_python = "/databricks/python3/bin/python3"
      #databricks_cluster azure_attributes
      availability          = var.DATABRICKS_CLUSTER_AVAILABILITY
      first_on_demand       = 1
      spot_bid_max_price    = -1
      python_package        = "dacite==1.6.0"
      init_script_workspace = "/Shared/init_packages.sh"
    }
  }
}
