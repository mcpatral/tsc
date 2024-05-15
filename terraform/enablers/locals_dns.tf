locals {
  private_endpoint_general_objects_aux = {
    sa_tfstate = {
      resource_name    = "sa${local.name_base_no_dash}tfstate"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base}-state/providers/Microsoft.Storage/storageAccounts/sa${local.name_base_no_dash}tfstate"
      subresource_name = "blob"
    }
    kv_master = {
      resource_name    = "kv-${local.name_base}-master"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base}-state/providers/Microsoft.KeyVault/vaults/kv-${local.name_base}-master"
      subresource_name = "vault"
    }
    kv_test = {
      resource_name    = "kv-${local.name_base_central}-test"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base_central}-central-manual/providers/Microsoft.KeyVault/vaults/kv-${local.name_base_central}-test"
      subresource_name = "vault"
    }
    "acr_${local.acr.name}" = {
      resource_name    = module.acr.name
      resource_id      = module.acr.id
      subresource_name = "registry"
    }
  }

  private_endpoint_monitor_objects_aux = {
    monitor_private_link_scope = {
      resource_name    = try(azurerm_monitor_private_link_scope.pls.0.name, null)
      resource_id      = try(azurerm_monitor_private_link_scope.pls.0.id, null)
      subresource_name = "azuremonitor"
    }
  }

  private_endpoint = {
    subnet_id            = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.endpoints}"]
    is_manual_connection = false
    objects              = var.AKS_OMS_AGENT_ENABLED ? merge(local.private_endpoint_general_objects_aux, local.private_endpoint_monitor_objects_aux) : local.private_endpoint_general_objects_aux
  }

  private_dns_zones_hub = {
    intrum = {
      name = var.ENVIRONMENT_DNS_ZONE_NAME
      tags = {}
    }
    azurecr = {
      name = "privatelink.azurecr.io"
      tags = {}
    }
    blob = {
      name = "privatelink.blob.core.windows.net"
      tags = {}
    }
    file = {
      name = "privatelink.file.core.windows.net"
      tags = {}
    }
    dfs = {
      name = "privatelink.dfs.core.windows.net"
      tags = {}
    }
    vault = {
      name = "privatelink.vaultcore.azure.net"
      tags = {}
    }
    # aml_api = {
    #   name = "privatelink.api.azureml.ms"
    #   tags = {}
    # }
    # aml_notebooks = {
    #   name = "privatelink.notebooks.azure.net"
    #   tags = {}
    # }
    agentsvc = {
      name = "privatelink.agentsvc.azure-automation.net"
      tags = {}
    }
    monitor = {
      name = "privatelink.monitor.azure.com"
      tags = {}
    }
    ods = {
      name = "privatelink.ods.opinsights.azure.com"
      tags = {}
    }
    oms = {
      name = "privatelink.oms.opinsights.azure.com"
      tags = {}
    }
    azuredatabricks = {
      name = "privatelink.azuredatabricks.net"
      tags = {}
    }
  }

  private_dns_zones_internal = {
    postgres = {
      name = "psql.privatedns.${var.ENVIRONMENT_TYPE}.${var.PROJECT}.postgres.database.azure.com"
      tags = {}
    },
    azuredatabricks = {
      name = "privatelink.azuredatabricks.net"
      tags = {}
    }
  }

  private_dns_zone = {
    link_name = "vnet-${local.name_base}-link"
    objects   = var.VNET_PEERED ? local.private_dns_zones_internal : merge(local.private_dns_zones_hub, local.private_dns_zones_internal)
  }

  private_dns_a_record_general_objects_aux = {
    sa_tfstate = {
      name                 = "sa${local.name_base_no_dash}tfstate"
      zone_key             = "blob"
      private_endpoint_key = "sa_tfstate"
    }
    kv_master = {
      name                 = "kv-${local.name_base}-master"
      zone_key             = "vault"
      private_endpoint_key = "kv_master"
    }
    kv_test = {
      name                 = "kv-${local.name_base_central}-test"
      zone_key             = "vault"
      private_endpoint_key = "kv_test"
    }
    "acr_${local.acr.name}" = {
      name                 = module.acr.name
      zone_key             = "azurecr"
      private_endpoint_key = "acr_${local.acr.name}"
    }
    "acr_${local.acr.name}.${var.LOCATION}.data" = {
      name                 = "${module.acr.name}.${var.LOCATION}.data"
      zone_key             = "azurecr"
      private_endpoint_key = "acr_${local.acr.name}"
    }
  }

  private_dns_a_record_monitor_aux = {
    fqdn_pls_dce_handler_control = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.LOCATION}-1.handler.control")][0], null)
    fqdn_pls_dce_metrics_ingest  = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.LOCATION}-1.metrics.ingest")][0], null)
    fqdn_pls_dce_ingest          = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.LOCATION}-1.ingest")][0], null)
  }

  # TODO: Remove private_dns_a_record_monitor_global_entries from Terraform and add entries creation logic to separate pipeline (similar to Dbw browser_authentication PE)
  private_dns_a_record_monitor_global_entries = var.CREATE_MONITOR_GLOBAL_ENTRIES ? {
    monitor_api = {
      name                 = "api"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_snapshot = {
      name                 = "snapshot"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_diagservices_query = {
      name                 = "diagservices-query"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_live = {
      name                 = "live"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_profiler = {
      name                 = "profiler"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_global_in_ai = {
      name                 = "global.in.ai"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    blob_scadvisorcontentpl = {
      name                 = "scadvisorcontentpl"
      zone_key             = "blob"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_global_handler_control = {
      name                 = "global.handler.control"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
  } : {}

  private_dns_a_record_monitor_objects_aux = merge({
    oms_log_analytics_workspace_id = {
      name                 = try(azurerm_log_analytics_workspace.law_main.0.workspace_id, null)
      zone_key             = "oms"
      private_endpoint_key = "monitor_private_link_scope"
    }
    ods_log_analytics_workspace_id = {
      name                 = try(azurerm_log_analytics_workspace.law_main.0.workspace_id, null)
      zone_key             = "ods"
      private_endpoint_key = "monitor_private_link_scope"
    }
    agentsvc_log_analytics_workspace_id = {
      name                 = try(azurerm_log_analytics_workspace.law_main.0.workspace_id, null)
      zone_key             = "agentsvc"
      private_endpoint_key = "monitor_private_link_scope"
    }
    "monitor_dce-${local.name_base}-main-cyog.${var.LOCATION}-1.handler.control" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_handler_control, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_handler_control) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    "monitor_dce-${local.name_base}-main-cyog.${var.LOCATION}-1.metrics.ingest" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_metrics_ingest, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_metrics_ingest) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    "monitor_dce-${local.name_base}-main-cyog.${var.LOCATION}-1.ingest" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_ingest, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_ingest) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
  }, local.private_dns_a_record_monitor_global_entries)

  private_dns_a_record_objects = var.AKS_OMS_AGENT_ENABLED ? merge(local.private_dns_a_record_general_objects_aux, local.private_dns_a_record_monitor_objects_aux) : local.private_dns_a_record_general_objects_aux

  private_dns_a_record = {
    ttl_seconds = 10
    objects     = var.VNET_PEERED ? {} : local.private_dns_a_record_objects
  }

  private_dns_a_record_hub = {
    ttl_seconds = 10
    objects     = var.VNET_PEERED ? local.private_dns_a_record_objects : {}
  }
}
