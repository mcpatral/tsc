locals {
  provider_default_storage_use_azuread = true
  provider_sas_storage_use_azuread     = false

  name_base         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash = replace(local.name_base, "-", "")

  remote_state = {
    resource_group_name  = "rg-${local.name_base}-state"
    storage_account_name = "sa${local.name_base_no_dash}tfstate"
    container_name       = "${var.ENVIRONMENT_TYPE}tfstate"
    use_azuread_auth     = true
  }
  enablers_tfstate_output = data.terraform_remote_state.enablers.outputs

  azure_fw_ip       = var.FIREWALL_PUBLIC_IP != null ? ["${var.FIREWALL_PUBLIC_IP}/32"] : []
  intrum_public_ips = var.VNET_PEERED ? concat(["194.11.129.242/32"], local.azure_fw_ip) : ["194.11.129.242/32"]
  authorized_ips = toset(
    compact(
      concat(local.intrum_public_ips, split(",", var.ADDITIONAL_AUTHORIZED_IPS), ["${local.enablers_tfstate_output.aks_devops_outbound_ip}/32"])
    )
  )

  account_group_ids = {
    "devops"    = var.DEVOPS_GROUP_ID,
    "developer" = var.DEVELOPER_GROUP_ID,
    "qa"        = var.QA_GROUP_ID
  }

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

  ecs_resources_tags         = {}
  monitor_resources_tags     = {}
  dbw_access_connectors_tags = {}

  connector_names = ["dbac-${local.name_base}-extloc"]

  aks = {
    sku                                 = "Standard"
    admin_username                      = "k8s_admin"
    kubernetes_version                  = "1.29.2"
    vnet_id                             = local.enablers_tfstate_output.networks_vnet_id
    private_cluster_enabled             = var.AKS_PRIVATE_CLUSTER
    private_cluster_public_fqdn_enabled = var.AKS_PRIVATE_CLUSTER ? false : null
    network_plugin                      = "kubenet"
    network_policy                      = "calico"
    network_outbound_type               = var.VNET_PEERED ? "userDefinedRouting" : "loadBalancer"
    open_service_mesh_enabled           = true
    api_server_authorized_ips           = local.authorized_ips
    private_dns_zone_id                 = var.AKS_PRIVATE_CLUSTER ? (var.VNET_PEERED ? "/subscriptions/${var.HUB_SUBSCRIPTION_ID}/resourceGroups/${local.enablers_tfstate_output.hub_private_dns_zone_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.${var.LOCATION}.azmk8s.io" : "System") : null
  }
  aks_clusters = {
    "main" = {
      acr_id                    = local.enablers_tfstate_output.acr_id_main
      dns_prefix                = "aks-${local.name_base}-main"
      network_pod_cidr          = "10.244.0.0/16"
      oidc_issuer_enabled       = false
      oms_agent_enabled         = var.AKS_OMS_AGENT_ENABLED
      workload_identity_enabled = false
      identity_type             = "UserAssigned"
      identity_id               = local.enablers_tfstate_output.mi_id_aks_main
      tags                      = {}
      default_node_pool = {
        vm_size              = "Standard_D2s_v3"
        node_count           = 2
        subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"]
        auto_scaling_enabled = false
        orchestrator_version = local.aks.kubernetes_version
      }
      cluster_node_pools = {
        "application" = {
          vm_size              = var.MAIN_AKS_SIZE
          node_count           = var.MAIN_AKS_NODE_COUNT
          node_min_count       = var.MAIN_AKS_NODE_COUNT
          node_max_count       = var.MAIN_AKS_NODE_MAX_COUNT
          node_max_pods        = var.MAIN_AKS_NODE_MAX_PODS
          subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"]
          orchestrator_version = local.aks.kubernetes_version
          mode                 = "User"
          scale_down_mode      = "Delete"
          auto_scaling_enabled = true
          node_labels = {
            pool = "application"
          }
        }
      }
    }
    # "aml" = {
    #   acr_id                    = module.acr.id
    #   dns_prefix                = "${var.ENVIRONMENT_TYPE}-aml"
    #   network_pod_cidr          = "10.244.0.0/16"
    #   oidc_issuer_enabled       = false
    #   oms_agent_enabled         = false
    #   workload_identity_enabled = false
    #   tags                      = {}
    #   default_node_pool = {
    #     # TODO: Review and define proper VM Size
    #     # TODO: Enable autoscaling and provide autoscaling profile in the future
    #     vm_size              = "Standard_DS2_v2"
    #     node_count           = tonumber(var.MAIN_AKS_NODE_COUNT)
    #     node_min_count       = tonumber(var.MAIN_AKS_NODE_COUNT)
    #     node_max_count       = tonumber(var.MAIN_AKS_NODE_MAX_COUNT)
    #     node_max_pods        = tonumber(var.MAIN_AKS_NODE_MAX_PODS)
    #     subnet_id            = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-aml"]
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
  #   tags                          = {}
  # }

  databricks = {
    #azurerm_databricks_workspace
    name_dbw                                            = "dbw-${local.name_base}"
    managed_resource_group_name                         = "dbw-mng-${local.name_base}"
    sku                                                 = var.DATABRICKS_SKU
    public_network_access_enabled                       = var.VNET_PEERED ? false : true
    network_security_group_rules_required               = var.VNET_PEERED ? "NoAzureDatabricksRules" : "AllRules"
    private_subnet_name                                 = "subnet-${local.name_base}-dbw-private"
    public_subnet_name                                  = "subnet-${local.name_base}-dbw-public"
    public_subnet_network_security_group_association_id = data.terraform_remote_state.enablers.outputs.nsg_ids["nsg-${local.name_base}-dbw"]
    tags = {
      DataClassification = "Restricted"
    }
  }

  postgresql = {
    name                         = "psqlflexsrv-${local.name_base}"
    sku_name                     = var.POSTGRES_SKU
    psql_admin_user              = var.psqladminuser
    psql_admin_pwd               = var.psqladminpwd #TODO recheck how it will be easier to manage and rotate
    create_mode                  = "Default"
    delegated_subnet_id          = local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-postgres"]
    private_dns_zone_id          = local.enablers_tfstate_output.managed_private_dns_zone_id["postgres"]
    storage_mb                   = var.STORAGE_MB
    psql_version                 = "12"
    geo_redundant_backup_enabled = var.PAIR_PAAS
    max_connections              = var.POSTGRES_MAX_CONNECTIONS
    tags                         = {}

    #Database
    database_name = "airflow"
    collation     = "en_US.utf8"
    charset       = "utf8"

    #Diagnostic Settings
    diagnostic_set_name = "dspsql-logs-${local.name_base}"
    diagnostic_set_id   = var.CENTRAL_LAW_ID != null ? var.CENTRAL_LAW_ID : local.enablers_tfstate_output.law_main_id

    principal_name = data.azuread_service_principal.spn.display_name
    object_id      = data.azuread_service_principal.spn.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
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

  kv_experation_days_to_hours = 300 * 24

  keyvault = {
    sku                        = "standard"
    soft_delete_retention_days = 30
    purge_protection           = true
    diagnostic_set_name        = "ds-${local.name_base}-keyvault-logs"
    diagnostic_set_id          = var.CENTRAL_LAW_ID != null ? var.CENTRAL_LAW_ID : local.enablers_tfstate_output.law_main_id

    // temp experation setup to avoid alerts

    // expiration date need to be in a specific format as well
    expiration_date = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.kv_experation_days_to_hours}h")

    common_access_policies = concat([
      {
        #TODO review and split permissions in future, looks not full and too masive
        resource_key   = "azure_devops_spn"
        object_id      = data.azurerm_client_config.current.object_id
        application_id = null
        secret_permissions = [
          "Get",
          "List",
          "Set",
          "Delete",
          "Recover",
          "Purge"
        ]
        key_permissions = [
          "Get",
          "List",
          "Create",
          "Delete",
          "Recover",
          "Purge",
          "UnwrapKey",
          "Update",
          "Verify",
          "WrapKey",
          "Release",
          "Rotate",
          "GetRotationPolicy",
          "SetRotationPolicy"
          # "Backup",
          # "Decrypt",
          # "Encrypt",
          # "Import",
          # "Restore",
          # "Sign",
        ]
      }
      ],
      [
        for key, value in local.account_group_ids : {
          resource_key   = "azure_group_${key}"
          object_id      = value
          application_id = null
          secret_permissions = [
            "Get",
            "List",
          ]
        }
    ])
    objects = {
      main = {
        subnets_id = values(local.enablers_tfstate_output.networks_vnet_subnets)
        public_ip  = local.authorized_ips
        access_policies = concat(
          [
            {
              resource_key   = "azure_databricks_spn"
              object_id      = "bf0677f5-0a17-485b-952b-2ceec05945b8"
              application_id = null
              secret_permissions = [
                "Get",
                "List",
              ]
            }
          ],
          [
            for key, value in local.storage_account.objects : {
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
        )
        kv_public_network_access_enabled = false
        tags = {
          DataClassification = "Restricted"
        }
      } /*
      aml = {
        subnets_id                       = values(local.enablers_tfstate_output.networks_vnet_subnets)
        public_ip                        = local.authorized_ips
        access_policies                    = []
        kv_public_network_access_enabled = false
      }*/
    }
  }

  key_vault_secret_aux = {
    main = {
      #"saamlkey"                = module.storage_account["aml"].primary_access_key
      "sadlkey" = module.storage_account["dl"].primary_access_key
      # "saverticakey"                            = module.storage_account["vertica"].primary_access_key
      "saairflowkey"  = module.storage_account_sas["airflow"].primary_access_key
      "satempkey"     = module.storage_account["temp"].primary_access_key
      "salawkey"      = module.storage_account["law"].primary_access_key
      "psqladminuser" = var.psqladminuser
      "psqladminpwd"  = var.psqladminpwd
      # "verticasuname"                           = var.verticasuname
      # "verticasupassword"                       = var.verticasupassword
      # "verticatlskey"                           = var.verticatlskey
      # "verticatlscrt"                           = var.verticatlscrt
      # "verticatlscakey"                         = var.verticatlscakey
      # "verticatlscacrt"                         = var.verticatlscacrt
      # "verticatlswebhookkey"                    = var.verticatlswebhookkey
      # "verticatlswebhookcrt"                    = var.verticatlswebhookcrt
      # "verticadbwritername"                     = var.verticadbwritername
      # "verticadbwriterpassword"                 = var.verticadbwriterpassword
      "airflowoauthspnclientid"     = var.airflowoauthspnclientid
      "airflowoauthspnclientsecret" = var.airflowoauthspnclientsecret
      "airflowtenantid"             = var.airflowtenantid
      "airflowfernetkey"            = var.airflowfernetkey
      "airflowpwd"                  = var.airflowpwd
      "databrickadmins"             = var.databrickadmins
      "psqlairflowpwd"              = var.psqlairflowpwd
      "psqlairflowuser"             = var.psqlairflowuser
      "clienttlskey"                = var.clienttlskey
      "clienttlscrt"                = var.clienttlscrt
      "airflowsmtpclientsecret"     = var.airflowsmtpclientsecret
      "airflowsmtpclientid"         = var.airflowsmtpclientid
      "airflowdbwspclientid"        = var.airflowdbwspclientid
      "airflowdbwspclientsecret"    = var.airflowdbwspclientsecret
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
}