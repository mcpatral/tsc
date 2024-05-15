#TODO review
resource "databricks_grants" "dbw_grants" {
  catalog = databricks_catalog.silver.name
  grant {
    principal  = var.SPN_DEVOPS_CLIENT_ID
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = data.azurerm_client_config.current.client_id
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = var.DATABRICKS_AIRFLOW_GROUP_NAME
    privileges = local.airflow_spn_permissions
  }
  grant {
    principal  = var.DATABRICKS_DEV_GROUP
    privileges = ["USE_CATALOG", "USE_SCHEMA", "APPLY_TAG", "EXECUTE", "MODIFY", "SELECT"]
  }
  grant {
    principal  = var.DATABRICKS_QA_GROUP
    privileges = ["USE_CATALOG", "USE_SCHEMA", "APPLY_TAG", "EXECUTE", "MODIFY", "SELECT"]
  }
  grant {
    principal  = var.DATABRICKS_DEVOPS_GROUP
    privileges = ["USE_CATALOG", "USE_SCHEMA", "EXECUTE", "READ_VOLUME", "SELECT"]
  }
  grant {
    principal  = var.DATABRICKS_DS_GROUP
    privileges = ["USE_CATALOG", "USE_SCHEMA", "EXECUTE", "READ_VOLUME", "SELECT"]
  }
  dynamic "grant" {
    for_each = local.silver_groups
    content {
      principal  = "csg_DA_${upper(var.UNITY_CATALOG_ENVIRONMENT_TYPE)}_SHARED_READ_${grant.key}"
      privileges = ["USE_CATALOG"]
    }
  }
}

resource "databricks_grants" "external_grants" {
  for_each          = local.external_locations
  external_location = databricks_external_location.external_location["${each.key}"].id
  grant {
    principal  = var.SPN_DEVOPS_CLIENT_ID
    privileges = ["ALL_PRIVILEGES"]
  }
  grant {
    principal  = var.DATABRICKS_AIRFLOW_GROUP_NAME
    privileges = ["READ_FILES", "WRITE_FILES"]
  }
  depends_on = [databricks_grants.dbw_grants]
}

resource "databricks_permissions" "cluster_usage" {
  cluster_id = module.databricks_cluster["single"].databricks_cluster_id
  access_control {
    group_name       = var.DATABRICKS_AIRFLOW_GROUP_NAME
    permission_level = "CAN_RESTART"
  }
  access_control {
    group_name       = var.DATABRICKS_DEV_GROUP
    permission_level = "CAN_RESTART"
  }
  depends_on = [databricks_grants.dbw_grants]
}