resource "databricks_token" "pat" {
  comment          = "Created from Azure DevOps Pipelines"
  lifetime_seconds = 31536000 # 365 days
}

resource "databricks_permissions" "token_usage" {
  authorization = "tokens"
  access_control {
    group_name       = var.DATABRICKS_AIRFLOW_GROUP_NAME
    permission_level = "CAN_USE"
  }
  depends_on = [
    databricks_token.pat
  ]
}

resource "databricks_catalog" "silver" {
  metastore_id = var.DATABRICKS_METASTORE_ID
  name         = local.catalog_name
}

resource "databricks_schema" "silver_schemas" {
  for_each      = local.silver_schemas
  catalog_name  = databricks_catalog.silver.id
  name          = each.key
  force_destroy = var.FORCE_DESTROY_SILVER_SCHEMAS
  depends_on = [
    databricks_external_location.external_location
  ]
}

resource "databricks_external_location" "external_location" {
  for_each = local.external_locations
  name     = each.key
  url = format("abfss://%s@%s.dfs.core.windows.net",
    each.value.container_name,
  each.value.sa_name)
  credential_name = local.catalog_name

}

resource "databricks_secret_scope" "secret" {
  name = local.secret_scope_name
  keyvault_metadata {
    resource_id = local.secret_key_vault_id
    dns_name    = local.secret_key_vault_dns_name
  }
}

module "databricks_cluster" {
  source                                     = "../modules/databricks_cluster"
  for_each                                   = local.clusters
  name_dbw_cluster                           = "dbw-autocl-${local.name_base}-${each.key}"
  node_type_id                               = each.value.node_type_id
  driver_node_type_id                        = each.value.driver_node_type_id
  autotermination_minutes                    = each.value.autotermination_minutes
  data_security_mode                         = each.value.data_security_mode
  db_workspace_id                            = local.databricks_id
  db_workspace_host                          = local.db_workspace_host
  spnclientid                                = each.value.spnclientid
  min_workers                                = each.value.min_workers
  max_workers                                = each.value.max_workers
  spark_databricks_io_cache_enabled          = each.value.spark_databricks_io_cache_enabled
  spark_databricks_io_cache_maxDiskUsage     = each.value.spark_databricks_io_cache_maxDiskUsage
  spark_databricks_io_cache_maxMetaDataCache = each.value.spark_databricks_io_cache_maxMetaDataCache
  spark_databricks_delta_preview_enabled     = each.value.spark_databricks_delta_preview_enabled
  spark_databricks_aggressiveWindowDownS     = each.value.spark_databricks_aggressiveWindowDownS
  spark_databricks_env                       = var.ENVIRONMENT_TYPE
  spark_databricks_pyspark_python            = each.value.spark_databricks_pyspark_python
  availability                               = each.value.availability
  first_on_demand                            = each.value.first_on_demand
  spot_bid_max_price                         = each.value.spot_bid_max_price
  python_package                             = each.value.python_package
  init_script_workspace                      = each.value.init_script_workspace
}