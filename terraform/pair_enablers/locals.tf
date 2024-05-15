locals {
  provider_storage_use_azuread = true

  name_base_primary         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash_primary = replace(local.name_base_primary, "-", "")
  name_base                 = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.PAIR_LOCATION_SHORT}"
  name_base_no_dash         = replace(local.name_base, "-", "")
  name_base_central         = "${var.SUBSCRIPTION_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT_CENTRAL}"

  remote_state = {
    resource_group_name  = "rg-${local.name_base_primary}-state"
    storage_account_name = "sa${local.name_base_no_dash_primary}tfstate"
    container_name       = "${var.ENVIRONMENT_TYPE}tfstate"
    use_azuread_auth     = true
  }

  enablers_tfstate_output = data.terraform_remote_state.enablers.outputs

  azure_dns_ip = "168.63.129.16"
  intrum_ips   = ["194.11.129.242/32"]
  authorized_ips = toset(
    compact(
      concat(local.intrum_ips, split(",", var.ADDITIONAL_AUTHORIZED_IPS))
    )
  )

  common_tags = {
    Country              = "Global"
    BusinessApplication  = "Gaia"
    SupportTeam          = var.SUBSCRIPTION_TYPE == "prod" ? "Infrastructure_and_Operations" : "Data_and_Analytics"
    Environment          = var.ENVIRONMENT_TYPE
    Company              = "Intrum"
    BusinessCriticallity = var.SUBSCRIPTION_TYPE == "prod" ? "High" : "Low"
    Project              = var.PROJECT
    CostCentre           = "Common"
    DataClassification   = "Internal"
  }

  acr = {
    name = "main"
  }

  aks = {
    sku                           = "Standard"
    admin_username                = "azureuser"
    kubernetes_version            = "1.28.3"
    api_server_authorized_ips     = local.authorized_ips
    network_plugin                = "kubenet"
    network_policy                = "calico"
    open_service_mesh_enabled     = true
    name                          = "devops-agents"
    public_network_access_enabled = true
    private_cluster_enabled       = false
    dns_prefix                    = "${var.ENVIRONMENT_TYPE}-devops-agents"
    network_lb_sku                = "standard"
    network_outbound_type         = "loadBalancer"
    network_pod_cidr              = "10.244.0.0/16"
  }
  aks_default_node_pool = {
    # TODO: Review and define proper VM Size
    vm_size              = var.DEVOPS_AKS_SIZE
    node_count           = tonumber(var.DEVOPS_AKS_NODE_COUNT)
    subnet_id            = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.devops}"]
    auto_scaling_enabled = false
    oms_agent_enabled    = var.AKS_OMS_AGENT_ENABLED
    orchestrator_version = local.aks.kubernetes_version
  }

  prometheus_grafana = {
    grafana_api_key_enabled                   = true
    grafana_deterministic_outbound_ip_enabled = false
    grafana_public_network_access_enabled     = true
    tags                                      = {}
    roles                                     = {
      admin_group_ids  = toset([var.DEVOPS_GROUP_ID])
      editor_group_ids = []
      viewer_group_ids = toset([var.DEVELOPER_GROUP_ID, var.QA_GROUP_ID])
    }
  }

  private_dns_zone = {
    link_name = "vnet-${local.name_base}-link"
    objects   = {
      intrum = {
        name = "${var.ENVIRONMENT_TYPE}.da.intrum.cloud"
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
      postgres = {
        name = "psql.privatedns.${var.ENVIRONMENT_TYPE}.${var.PROJECT}.postgres.database.azure.com"
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
    }
  }

  private_endpoint_general_objects_aux = {
    sa_tfstate = {
      resource_name    = "sa${local.name_base_no_dash_primary}tfstate"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base_primary}-state/providers/Microsoft.Storage/storageAccounts/sa${local.name_base_no_dash_primary}tfstate"
      subresource_name = "blob"
    }
    kv_master = {
      resource_name    = "kv-${local.name_base_primary}-master"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base_primary}-state/providers/Microsoft.KeyVault/vaults/kv-${local.name_base_primary}-master"
      subresource_name = "vault"
    }
    kv_test = {
      resource_name    = "kv-${local.name_base_central}-test"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base_central}-central-manual/providers/Microsoft.KeyVault/vaults/kv-${local.name_base_central}-test"
      subresource_name = "vault"
    }
    "acr_${local.acr.name}" = {
      resource_name    = local.enablers_tfstate_output.acr_name_main
      resource_id      = local.enablers_tfstate_output.acr_id_main
      subresource_name = "registry"
    }

    #TODO: Change to more dynamic src (from dev for test, from test for uat, from uat to prod)
    acr_master = {
      resource_name    = "acrdevdaweucentralmanual"
      resource_id      = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/resourceGroups/rg-${local.name_base_central}-central-manual/providers/Microsoft.ContainerRegistry/registries/acrdevdaweucentralmanual"
      subresource_name = "registry"
    }
  }

  private_endpoint_monitor_objects_aux = {
    monitor_private_link_scope = {
      resource_name    = "pls-${local.name_base_primary}-main"
      resource_id      = try(local.enablers_tfstate_output.pls_id, null)
      subresource_name = "azuremonitor"
    }
  }

  private_endpoint = {
    subnet_id            = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.endpoints}"]
    is_manual_connection = false
    objects              = var.AKS_OMS_AGENT_ENABLED ? merge(local.private_endpoint_general_objects_aux, local.private_endpoint_monitor_objects_aux) : local.private_endpoint_general_objects_aux
  }

  private_dns_a_record_general_objects_aux = {
    "acr_${local.acr.name}.${var.PAIR_LOCATION}.data" = {
      name                 = "${local.enablers_tfstate_output.acr_name_main}.${var.PAIR_LOCATION}.data"
      zone_key             = "azurecr"
      private_endpoint_key = "acr_${local.acr.name}"
    }
  }

  private_dns_a_record_monitor_aux = {
    fqdn_pls_dce_handler_control = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.PAIR_LOCATION}-1.handler.control")][0], null)
    fqdn_pls_dce_metrics_ingest  = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.PAIR_LOCATION}-1.metrics.ingest")][0], null)
    fqdn_pls_dce_ingest          = try([for config in azurerm_private_endpoint.pe["monitor_private_link_scope"].custom_dns_configs : config.fqdn if strcontains(config.fqdn, ".${var.PAIR_LOCATION}-1.ingest")][0], null)
  }

  private_dns_a_record_monitor_objects_aux = {
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
    "monitor_dce-${local.name_base}-main-cyog.${var.PAIR_LOCATION}-1.handler.control" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_handler_control, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_handler_control) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    "monitor_dce-${local.name_base}-main-cyog.${var.PAIR_LOCATION}-1.metrics.ingest" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_metrics_ingest, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_metrics_ingest) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    "monitor_dce-${local.name_base}-main-cyog.${var.PAIR_LOCATION}-1.ingest" = {
      name                 = try(substr(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_ingest, 0, length(local.private_dns_a_record_monitor_aux.fqdn_pls_dce_ingest) - length(".monitor.azure.com")), null)
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
  }
  
  private_dns_a_record_objects = var.VNET_PEERED ? (var.AKS_OMS_AGENT_ENABLED ? merge(local.private_dns_a_record_general_objects_aux, local.private_dns_a_record_monitor_objects_aux) : local.private_dns_a_record_general_objects_aux) : {}

  private_dns_a_record = {
    ttl_seconds = 10
    objects     = local.private_dns_a_record_objects
  }

  private_dns_a_record_script_general_objects_aux = {
    sa_tfstate = {
      name                 = "sa${local.name_base_no_dash_primary}tfstate"
      zone_key             = "blob"
      private_endpoint_key = "sa_tfstate"
    }
    kv_master = {
      name                 = "kv-${local.name_base_primary}-master"
      zone_key             = "vault"
      private_endpoint_key = "kv_master"
    }
    kv_test = {
      name                 = "kv-${local.name_base_central}-test"
      zone_key             = "vault"
      private_endpoint_key = "kv_test"
    }
    "acr_${local.acr.name}" = {
      name                 = local.enablers_tfstate_output.acr_name_main
      zone_key             = "azurecr"
      private_endpoint_key = "acr_${local.acr.name}"
    }
  }

  private_dns_a_record_script_monitor_objects_aux = {
    monitor_api = {
      name                 = "api"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_global_in_ai = {
      name                 = "global.in.ai"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    monitor_global_handler_control = {
      name                 = "global.handler.control"
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
    monitor_snapshot = {
      name                 = "snapshot"
      zone_key             = "monitor"
      private_endpoint_key = "monitor_private_link_scope"
    }
    blob_scadvisorcontentpl = {
      name                 = "scadvisorcontentpl"
      zone_key             = "blob"
      private_endpoint_key = "monitor_private_link_scope"
    }
  }

  private_dns_a_record_script_objects = var.VNET_PEERED ? (var.AKS_OMS_AGENT_ENABLED ? merge(local.private_dns_a_record_script_general_objects_aux, local.private_dns_a_record_script_monitor_objects_aux) : local.private_dns_a_record_script_general_objects_aux) : {}
  
  private_dns_a_record_script = {
    ttl_seconds = 10
    objects     = local.private_dns_a_record_script_objects
  }
}