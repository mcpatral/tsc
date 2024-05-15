resource "databricks_sql_table" "currency_rates" {
  name               = local.databricks_currency_table_name
  catalog_name       = databricks_catalog.silver.name
  schema_name        = tolist(local.silver_schemas)[0]
  table_type         = local.databricks_currency_table_type
  data_source_format = local.databricks_currency_data_source_format
  storage_location   = local.databricks_currency_storage_location

  column {
    name = "currency_code"
    type = "string"
  }
  column {
    name = "ts_for_date"
    type = "bigint"
  }
  column {
    name = "for_year"
    type = "int"
  }
  column {
    name = "base_currency"
    type = "string"
  }
  column {
    name = "rate"
    type = "decimal(14,6)"
  }
  column {
    name = "source"
    type = "string"
  }
  column {
    name = "ts_added_date"
    type = "bigint"
  }
  column {
    name = "auto_generated"
    type = "boolean"
  }

  partitions = ["for_year"]

  depends_on = [
    databricks_schema.silver_schemas["lookup"]
  ]
}
