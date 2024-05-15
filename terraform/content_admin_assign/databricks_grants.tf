resource "databricks_permission_assignment" "accounts_admin" {
  principal_id = tonumber(var.DATABRICKS_ADMIN_GROUP_ID)
  permissions  = ["USER"]
}

