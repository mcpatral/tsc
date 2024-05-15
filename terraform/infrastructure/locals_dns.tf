locals {
  private_endpoints_objects_aux = {
    # "acr_${local.acr.name}" = {
    #   resource_name        = "acr${local.name_base_no_dash}${local.acr.name}"
    #   resource_id          = module.acr.id
    #   subresource_name     = "registry"
    # }
    kv_main = {
      resource_name    = "kv-${local.name_base}-main"
      resource_key     = "main"
      subresource_name = "vault"
    }
    # kv_aml = {
    #   resource_name        = "kv-${local.name_base}-aml"
    #   resource_key         = "aml"
    #   subresource_name     = "vault"
    # }
    # sa_aml_blob = {
    #   resource_name        = "sa${local.name_base_no_dash}aml"
    #   resource_key         = "aml"
    #   subresource_name     = "blob"
    # }
    # sa_aml_file = {
    #   resource_name        = "sa${local.name_base_no_dash}aml"
    #   resource_key         = "aml"
    #   subresource_name     = "file"
    # }
    # sa_vertica_blob = {
    #   resource_name    = "sa${local.name_base_no_dash}vertica"
    #   resource_key     = "vertica"
    #   subresource_name = "blob"
    # }
    sa_airflow_blob = {
      resource_name    = "sa${local.name_base_no_dash}airflow"
      resource_key     = "airflow"
      subresource_name = "blob"
    }
    sa_dl_blob = {
      resource_name    = "sa${local.name_base_no_dash}dl"
      resource_key     = "dl"
      subresource_name = "blob"
    }
    sa_dl_file = {
      resource_name    = "sa${local.name_base_no_dash}dl"
      resource_key     = "dl"
      subresource_name = "file"
    }
    sa_dl_dfs = {
      resource_name    = "sa${local.name_base_no_dash}dl"
      resource_key     = "dl"
      subresource_name = "dfs"
    }
    sa_temp_blob = {
      resource_name    = "sa${local.name_base_no_dash}temp"
      resource_key     = "temp"
      subresource_name = "blob"
    }
    sa_temp_dfs = {
      resource_name    = "sa${local.name_base_no_dash}temp"
      resource_key     = "temp"
      subresource_name = "dfs"
    }
    sa_law_blob = {
      resource_name    = "sa${local.name_base_no_dash}law"
      resource_key     = "law"
      subresource_name = "blob"
    }
    sa_law_file = {
      resource_name    = "sa${local.name_base_no_dash}law"
      resource_key     = "law"
      subresource_name = "file"
    }
    sa_law_dfs = {
      resource_name    = "sa${local.name_base_no_dash}law"
      resource_key     = "law"
      subresource_name = "dfs"
    }
  }
  private_endpoints_pair_objects_aux = {
    sa_airflow_pair_blob = {
      resource_name    = "sa${var.ENVIRONMENT_TYPE}${var.PROJECT}${var.PAIR_LOCATION_SHORT}airflow"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.PAIR_LOCATION_SHORT}/providers/Microsoft.Storage/storageAccounts/sa${var.ENVIRONMENT_TYPE}${var.PROJECT}${var.PAIR_LOCATION_SHORT}airflow"
      subresource_name = "blob"
    }
  }
  private_endpoint = {
    subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"]
    is_manual_connection = false
    objects              = var.RESTORE_FROM_PAIR_TO_MAIN ? merge(local.private_endpoints_objects_aux, local.private_endpoints_pair_objects_aux) : local.private_endpoints_objects_aux
  }

  private_dns_a_record_objects_aux = {
    kv_main = {
      name                 = "kv-${local.name_base}-main"
      zone_key             = "vault"
      private_endpoint_key = "kv_main"
    }
    # kv_aml = {
    #   name                 = "kv-${local.name_base}-aml"
    #   zone_key             = "vault"
    #   private_endpoint_key = "kv_aml"
    # }
    # sa_aml_blob = {
    #   name                 = "sa${local.name_base_no_dash}aml"
    #   zone_key             = "blob"
    #   private_endpoint_key = "sa_aml_blob"
    # }
    # sa_aml_file = {
    #   name                 = "sa${local.name_base_no_dash}aml"
    #   zone_key             = "file"
    #   private_endpoint_key = "sa_aml_file"
    # }
    # sa_vertica_blob = {
    #   name                 = "sa${local.name_base_no_dash}vertica"
    #   zone_key             = "blob"
    #   private_endpoint_key = "sa_vertica_blob"
    # }
    sa_airflow_blob = {
      name                 = "sa${local.name_base_no_dash}airflow"
      zone_key             = "blob"
      private_endpoint_key = "sa_airflow_blob"
    }
    sa_dl_blob = {
      name                 = "sa${local.name_base_no_dash}dl"
      zone_key             = "blob"
      private_endpoint_key = "sa_dl_blob"
    }
    sa_dl_file = {
      name                 = "sa${local.name_base_no_dash}dl"
      zone_key             = "file"
      private_endpoint_key = "sa_dl_file"
    }
    sa_dl_dfs = {
      name                 = "sa${local.name_base_no_dash}dl"
      zone_key             = "dfs"
      private_endpoint_key = "sa_dl_dfs"
    }
    sa_temp_blob = {
      name                 = "sa${local.name_base_no_dash}temp"
      zone_key             = "blob"
      private_endpoint_key = "sa_temp_blob"
    }
    sa_temp_dfs = {
      name                 = "sa${local.name_base_no_dash}temp"
      zone_key             = "dfs"
      private_endpoint_key = "sa_temp_dfs"
    }
    sa_law_blob = {
      name                 = "sa${local.name_base_no_dash}law"
      zone_key             = "blob"
      private_endpoint_key = "sa_law_blob"
    }
    sa_law_file = {
      name                 = "sa${local.name_base_no_dash}law"
      zone_key             = "file"
      private_endpoint_key = "sa_law_file"
    }
    sa_law_dfs = {
      name                 = "sa${local.name_base_no_dash}law"
      zone_key             = "dfs"
      private_endpoint_key = "sa_law_dfs"
    }
  }
  private_dns_a_record_pair_objects_aux = {
    sa_airflow_pair_blob = {
      resource_name        = "sa${var.ENVIRONMENT_TYPE}${var.PROJECT}${var.PAIR_LOCATION_SHORT}airflow"
      zone_key             = "blob"
      private_endpoint_key = "sa_airflow_pair_blob"
    }
  }

  private_dns_a_record_objects = var.RESTORE_FROM_PAIR_TO_MAIN ? merge(local.private_dns_a_record_objects_aux, local.private_dns_a_record_pair_objects_aux) : local.private_dns_a_record_objects_aux

  private_dns_a_record = {
    ttl_seconds = 10
    objects     = var.VNET_PEERED ? {} : local.private_dns_a_record_objects
  }
  private_dns_a_record_hub = {
    ttl_seconds = 10
    objects     = var.VNET_PEERED ? local.private_dns_a_record_objects : {}
  }
}