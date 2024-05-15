resource "databricks_cluster" "autoscaling" {
  cluster_name            = var.name_dbw_cluster
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = var.node_type_id
  driver_node_type_id     = var.driver_node_type_id
  single_user_name        = var.spnclientid
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = var.data_security_mode
  custom_tags             = var.tags
  autoscale {
    min_workers = var.min_workers
    max_workers = var.max_workers
  }
  spark_conf = {
    "spark.databricks.io.cache.enabled" : var.spark_databricks_io_cache_enabled,
    "spark.databricks.io.cache.maxDiskUsage" : "${var.spark_databricks_io_cache_maxDiskUsage}",
    "spark.databricks.io.cache.maxMetaDataCache" : "${var.spark_databricks_io_cache_maxMetaDataCache}"
    "spark.databricks.delta.preview.enabled" : "${var.spark_databricks_delta_preview_enabled}"
    "spark.databricks.aggressiveWindowDownS" : "${var.spark_databricks_aggressiveWindowDownS}"
    #"spark.password": "{{secrets/${var.secret_scope_name}/${var.secret_token_name}}}" #MORE INFO https://docs.databricks.com/security/secrets/secrets.html#language-sql
  }
  spark_env_vars = {
    "ENVIRONMENT"    = var.spark_databricks_env,
    "PYSPARK_PYTHON" = var.spark_databricks_pyspark_python
  }
  azure_attributes {
    availability       = var.availability
    first_on_demand    = var.first_on_demand
    spot_bid_max_price = var.spot_bid_max_price
  }

  library {
    pypi {
      package = var.python_package
    }
  }
  cluster_log_conf {
    dbfs {
      destination = "dbfs:/cluster-logs/${var.name_dbw_cluster}"
    }
  }

  init_scripts {
    workspace {
      destination = var.init_script_workspace
    }
  }
}
