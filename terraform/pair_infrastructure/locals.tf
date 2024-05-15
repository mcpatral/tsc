locals {
  provider_default_storage_use_azuread = true
  provider_sas_storage_use_azuread     = false

  name_base_primary         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash_primary = replace(local.name_base_primary, "-", "")
  name_base                 = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.PAIR_LOCATION_SHORT}"
  name_base_no_dash         = replace(local.name_base, "-", "")

  remote_state = {
    resource_group_name  = "rg-${local.name_base_primary}-state"
    storage_account_name = "sa${local.name_base_no_dash_primary}tfstate"
    container_name       = "${var.ENVIRONMENT_TYPE}tfstate"
    use_azuread_auth     = true
  }
  enablers_tfstate_output       = data.terraform_remote_state.enablers.outputs
  infrastructure_tfstate_output = data.terraform_remote_state.infrastructure.outputs

  intrum_ips = ["194.11.129.242/32"]
  authorized_ips = toset(
    compact(
      concat(local.intrum_ips, split(",", var.ADDITIONAL_AUTHORIZED_IPS), ["${local.enablers_tfstate_output.aks_devops_outbound_ip}/32"])
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

  connector_names = ["dbac-${local.name_base}-extloc", "dbac-${local.name_base}-meta"]

  # acr = {
  #   name = "aml"
  # }

  aks = {
    # TODO: To disable public network access once Private cluster and VPN will be enabled
    sku                       = "Standard"
    admin_username            = "k8s_admin"
    kubernetes_version        = "1.28.3"
    vnet_id                   = local.enablers_tfstate_output.networks_vnet_id
    private_cluster_enabled   = false
    network_plugin            = "kubenet"
    network_policy            = "calico"
    open_service_mesh_enabled = true
    api_server_authorized_ips = local.authorized_ips
  }
  aks_clusters = {
    "main" = {
      acr_id                    = local.enablers_tfstate_output.acr_id_main
      dns_prefix                = var.ENVIRONMENT_TYPE
      network_pod_cidr          = "10.244.0.0/16"
      oidc_issuer_enabled       = false
      oms_agent_enabled         = var.AKS_OMS_AGENT_ENABLED
      workload_identity_enabled = false
      default_node_pool = {
        # TODO: Review and define proper VM Size
        # TODO: Enable autoscaling and provide autoscaling profile in the future
        vm_size              = var.MAIN_AKS_SIZE
        node_count           = tonumber(var.MAIN_AKS_NODE_COUNT)
        node_min_count       = tonumber(var.MAIN_AKS_NODE_COUNT)
        node_max_count       = tonumber(var.MAIN_AKS_NODE_MAX_COUNT)
        node_max_pods        = tonumber(var.MAIN_AKS_NODE_MAX_PODS)
        subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"]
        auto_scaling_enabled = true
        orchestrator_version = local.aks.kubernetes_version
      }
    }
    # "aml" = {
    #   acr_id              = local.infrastructure_tfstate_output.acr_id_aml
    #   dns_prefix          = "${var.ENVIRONMENT_TYPE}-aml"
    #   network_pod_cidr    = "10.244.0.0/16"
    #   oidc_issuer_enabled = false
    #   oms_agent_enabled   = false
    #   default_node_pool = {
    #     # TODO: Review and define proper VM Size
    #     # TODO: Enable autoscaling and provide autoscaling profile in the future
    #     vm_size              = "Standard_DS2_v2"
    #     node_count           = tonumber(var.MAIN_AKS_NODE_COUNT)
    #     node_min_count       = tonumber(var.MAIN_AKS_NODE_COUNT)
    #     node_max_count       = tonumber(var.MAIN_AKS_NODE_MAX_COUNT)
    #     node_max_pods        = tonumber(var.MAIN_AKS_NODE_MAX_PODS)
    #     subnet_id            = local.enablers_tfstate_output.vnet_subnet_aks_aml
    #     auto_scaling_enabled = false
    #     orchestrator_version = local.aks.kubernetes_version
    #   }
    # }
  }

  prometheus_grafana = {}

  # aml = {
  #   name                          = "amlw${local.name_base_no_dash}"
  #   appinsights_id                = module.appinsights.id
  #   key_vault_id                  = module.keyvault["aml"].key_vault_id
  #   storage_account_id            = try(module.storage_account["aml"].id, module.storage_account_sas["aml"].id)
  #   acr_id                        = module.acr.id
  #   public_network_access_enabled = false
  #   identity_type                 = "SystemAssigned"
  # }

  databricks = {
    #azurerm_databricks_workspace
    name_dbw                                            = "dbw-${local.name_base}"
    managed_resource_group_name                         = "dbw-mng-${local.name_base}"
    sku                                                 = var.DATABRICKS_SKU
    public_network_access_enabled                       = true
    private_subnet_name                                 = "subnet-${local.name_base}-dbw-private"
    public_subnet_name                                  = "subnet-${local.name_base}-dbw-public"
    public_subnet_network_security_group_association_id = data.terraform_remote_state.enablers.outputs.nsg_ids["nsg-${local.name_base}-dbw"]
    #databricks_secret_scope
    secret_scope_name  = "kv-main-scope"
    key_vault_id       = local.infrastructure_tfstate_output.key_vault_id["main"]
    key_vault_dns_name = local.infrastructure_tfstate_output.key_vault_uri["main"]
    tags = {
      DataClassification = "Restricted"
    }
  }

  postgresql = {
    name                 = "psqlflexsrv-${local.name_base}"
    source_server_id     = local.infrastructure_tfstate_output.psql_server_id
    delegated_subnet_id  = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-postgres"]
    private_dns_zone_id  = local.enablers_tfstate_output.private_dns_zone_id["postgres"]
    geo_redundant_backup = "Enabled"
  }

  # TODO: Review how many AI resources we need to create
  # Might be needed to introduce complex data structures in case of multiple instances
  # appinsights = {
  #   name                          = "ai-${local.name_base}-aml"
  #   application_type              = "web"
  #   daily_data_cap_in_gb          = 30
  #   retention_in_days             = 30
  #   local_authentication_disabled = false
  #   internet_query_enabled        = true
  #   law_id                        = var.CENTRAL_LAW_ID != null ? var.CENTRAL_LAW_ID : local.enablers_tfstate_output.law_main_id
  # }

  keyvault = {}

  key_vault_access_policy = [
    for key, value in local.storage_account.objects : {
      key_vault_key  = "main"
      resource_key   = "sa_${key}_user_assigned_identity"
      object_id      = azurerm_user_assigned_identity.sa["${key}"].principal_id
      application_id = null
      key_permissions = [
        "Get",
        "UnwrapKey",
        "WrapKey"
      ]
    } if value["create_customer_managed_key"] == true
  ]

  key_vault_secret_aux = {
    main = {
      # "saamlkeypair"     = module.storage_account["aml"].primary_access_key
      "saairflowkeypair" = module.storage_account_sas["airflow"].primary_access_key
      "dbwpattokenpair"  = module.databricks.databricks_pat_token_value
      "dbwidtokenpair"   = module.databricks.databricks_pat_id
    }
  }

  key_vault_secret = merge([
    for kv_key, secrets in local.key_vault_secret_aux : {
      for name, value in secrets : "${kv_key}_${name}" => {
        kv_key       = kv_key
        secret_name  = name
        secret_value = value
      }
    }
  ]...)

  key_vault_key_aux = {
    main = [
      for key, value in local.storage_account.objects :
      "sa${local.name_base_no_dash}${key}" if value.create_customer_managed_key == true
    ]
  }
  key_vault_key = {
    key_type = "RSA"
    key_size = 2048
    key_opts = [
      "encrypt",
      "decrypt",
      "sign",
      "verify",
      "wrapKey",
      "unwrapKey",
    ]
    objects = merge([
      for kv_key, key_names in local.key_vault_key_aux : {
        for key_name in key_names : "${kv_key}_${key_name}" => {
          kv_key   = kv_key
          key_name = key_name
        }
      }
    ]...)
  }

  private_endpoint = {
    subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"]
    is_manual_connection = false
    objects = {
      # "acr_${local.acr.name}" = {
      #   resource_name        = local.infrastructure_tfstate_output.acr_name_aml
      #   resource_id          = local.infrastructure_tfstate_output.acr_id_aml
      #   subresource_name     = "registry"
      # }
      kv_main = {
        resource_name    = local.infrastructure_tfstate_output.key_vault_name["main"]
        resource_id      = local.infrastructure_tfstate_output.key_vault_id["main"]
        subresource_name = "vault"
      }
      # kv_aml = {
      #   resource_name        = "kv-${local.name_base}-aml"
      #   resource_id          = module.keyvault["aml"].key_vault_id
      #   subresource_name     = "vault"
      # }
      # sa_aml_blob = {
      #   resource_name        = "sa${local.name_base_no_dash}aml"
      #   resource_id          = module.storage_account["aml"].id
      #   subresource_name     = "blob"
      # }
      # sa_aml_file = {
      #   resource_name        = "sa${local.name_base_no_dash}aml"
      #   resource_id          = module.storage_account["aml"].id
      #   subresource_name     = "file"
      # }
      # sa_vertica_blob = {
      #   resource_name    = local.infrastructure_tfstate_output.sa_name["vertica"]
      #   resource_id      = local.infrastructure_tfstate_output.sa_id["vertica"]
      #   subresource_name = "blob"
      # }
      sa_airflow_blob = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["airflow"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["airflow"]
        subresource_name = "blob"
      }
      sa_airflow_pair_blob = {
        resource_name    = "sa${local.name_base_no_dash}airflow"
        resource_key     = "airflow"
        subresource_name = "blob"
      }
      sa_dl_blob = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["dl"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["dl"]
        subresource_name = "blob"
      }
      sa_dl_file = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["dl"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["dl"]
        subresource_name = "file"
      }
      sa_dl_dfs = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["dl"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["dl"]
        subresource_name = "dfs"
      }
      sa_temp_blob = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["temp"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["temp"]
        subresource_name = "blob"
      }
      sa_temp_dfs = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["temp"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["temp"]
        subresource_name = "dfs"
      }
      sa_metastore_dfs = {
        resource_name    = local.infrastructure_tfstate_output.sa_name["metastore"]
        resource_id      = local.infrastructure_tfstate_output.sa_id["metastore"]
        subresource_name = "dfs"
      }
    }
  }

  private_dns_a_record = {
    ttl_seconds = 10
    objects = {
      sa_airflow_pair_blob = {
        name                 = "sa${var.ENVIRONMENT_TYPE}${var.PROJECT}${var.PAIR_LOCATION_SHORT}airflow"
        zone_key             = "blob"
        private_endpoint_key = "sa_airflow_pair_blob"
      }
      # "acr_${local.acr.name}.${var.PAIR_LOCATION}.data" = {
      #   name                 = "acr${local.name_base_no_dash}${local.acr.name}.${var.PAIR_LOCATION}.data"
      #   zone_key             = "azurecr"
      #   private_endpoint_key = "acr_${local.acr.name}"
      # }
    }
  }

  private_dns_a_record_null_resource = {
    ttl_seconds = 10
    objects = {
      # "acr_${local.acr.name}" = {
      #   name                 = local.infrastructure_tfstate_output.acr_name_aml
      #   zone_key             = "registry"
      #   private_endpoint_key = "acr_${local.acr.name}"
      # }
      kv_main = {
        name                 = local.infrastructure_tfstate_output.key_vault_name["main"]
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
      #   name                 = local.infrastructure_tfstate_output.sa_name["vertica"]
      #   zone_key             = "blob"
      #   private_endpoint_key = "sa_vertica_blob"
      # }
      sa_airflow_blob = {
        name                 = local.infrastructure_tfstate_output.sa_name["airflow"]
        zone_key             = "blob"
        private_endpoint_key = "sa_airflow_blob"
      }
      sa_dl_blob = {
        name                 = local.infrastructure_tfstate_output.sa_name["dl"]
        zone_key             = "blob"
        private_endpoint_key = "sa_dl_blob"
      }
      sa_dl_file = {
        name                 = local.infrastructure_tfstate_output.sa_name["dl"]
        zone_key             = "file"
        private_endpoint_key = "sa_dl_file"
      }
      sa_dl_dfs = {
        name                 = local.infrastructure_tfstate_output.sa_name["dl"]
        zone_key             = "dfs"
        private_endpoint_key = "sa_dl_dfs"
      }
      sa_temp_blob = {
        name                 = local.infrastructure_tfstate_output.sa_name["temp"]
        zone_key             = "blob"
        private_endpoint_key = "sa_temp_blob"
      }
      sa_temp_dfs = {
        name                 = local.infrastructure_tfstate_output.sa_name["temp"]
        zone_key             = "dfs"
        private_endpoint_key = "sa_temp_dfs"
      }
      sa_metastore_dfs = {
        name                 = local.infrastructure_tfstate_output.sa_name["metastore"]
        zone_key             = "dfs"
        private_endpoint_key = "sa_metastore_dfs"
      }
    }
  }
}