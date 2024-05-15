resource "databricks_permission_assignment" "add_airflow_spn_group" {
  principal_id = var.DATABRICKS_AIRFLOW_GROUP_ID
  permissions  = ["USER"]
}

resource "databricks_permission_assignment" "system_group_grant" {
  for_each     = local.silver_group_ids
  principal_id = each.key
  permissions  = ["USER"]
}