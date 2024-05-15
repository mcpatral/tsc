locals {
  action_groups = {
    airflow_internal_dev = {
      resource_name = "ag-${local.name_base}-afintdev"
      short_name    = "afintdev"
      email_receiver_common = [
        {
          name           = "airflow_internal_dev"
          email_receiver = var.AIRFLOW_INTERNAL_DEV_EMAIL
        }
      ]
    }
    devops_internal_dev = {
      resource_name = "ag-${local.name_base}-devopsintdev"
      short_name    = "devopsintdev"
      email_receiver_common = [
        for index, value in split(",", var.DEVOPS_INTERNAL_EMAIL) : {
          name           = "devops_internal_dev_${index}"
          email_receiver = value
        }
      ]
    }
  }

  log_alerts = {
    airflow_cff2_errors = {
      resource_name        = "ar-${local.name_base}-afcff2err"
      evaluation_frequency = "PT5M"
      window_duration      = "PT5M"
      scopes               = [module.aks["main"].aks_cluster_id]
      severity             = 3
      description          = "CFF2_Errors"
      display_name         = "CFF2_Errors"
      action_groups        = [azurerm_monitor_action_group.action_group["airflow_internal_dev"].id]
      criteria = {
        query                   = <<-QUERY
                    ContainerLogV2
                    | where PodName contains "cff"
                    | where ContainerName contains "base"
                    | where LogMessage contains "Error code: "
                    QUERY
        time_aggregation_method = "Count"
        threshold               = 1
        operator                = "GreaterThanOrEqual"

        dimension = {
          name     = "PodName"
          operator = "Include"
          values   = ["*"]
        }
        failing_periods = {
          minimum_failing_periods_to_trigger_alert = 1
          number_of_evaluation_periods             = 1
        }
      }
    }
    airflow_cff2_python_errors = {
      resource_name        = "ar-${local.name_base}-afcff2pyerr"
      evaluation_frequency = "PT5M"
      window_duration      = "PT5M"
      scopes               = [module.aks["main"].aks_cluster_id]
      severity             = 3
      description          = "CFF2_Python_Errors"
      display_name         = "CFF2_Python_Errors"
      action_groups        = [azurerm_monitor_action_group.action_group["airflow_internal_dev"].id]
      criteria = {
        query                   = <<-QUERY
                    ContainerLogV2
                    | where PodName contains "cff"
                    | where ContainerName contains "base"
                    | where LogMessage contains "Task failed with exception"
                    QUERY
        time_aggregation_method = "Count"
        threshold               = 1
        operator                = "GreaterThanOrEqual"

        dimension = {
          name     = "PodName"
          operator = "Include"
          values   = ["*"]
        }
        failing_periods = {
          minimum_failing_periods_to_trigger_alert = 1
          number_of_evaluation_periods             = 1
        }
      }
    }
  }

  metric_alerts = {
    acr_storage_usage_alert = {
      name            = "ar-${local.name_base}-acrstorageusage"
      scopes          = [local.enablers_tfstate_output.acr_id_main]
      description     = "95% of storage provided in ACR Premium tier check. Consider cleaning up ACR to not exceed the limit of 500 GiB if triggered."
      auto_mitigate   = true
      frequency       = "PT30M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerRegistry/registries"
          metric_name            = "StorageUsed"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = var.ACR_STORAGE_USAGE_ALERT * (pow(1024, 3))
          skip_metric_validation = false
        }
      ]
    },
    sa_dl_availability = {
      name            = "ar-${local.name_base}-${module.storage_account["dl"].name}availability"
      scopes          = [module.storage_account["dl"].id]
      description     = "Storage Account ${module.storage_account["dl"].name} availability issues. Please check whether Storage account is available and contact Microsoft support for assistance if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Availability"
          aggregation            = "Average"
          operator               = "LessThan"
          threshold              = 100
          skip_metric_validation = false
        }
      ]
    },
    sa_dl_transaction_errors = {
      name            = "ar-${local.name_base}-${module.storage_account["dl"].name}transactions"
      scopes          = [module.storage_account["dl"].id]
      description     = "Storage Account ${module.storage_account["dl"].name} transaction issues detection. Please check whether Storage account is available and operating properly if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      dynamic_criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Transactions"
          aggregation            = "Total"
          operator               = "GreaterThan"
          alert_sensitivity      = "High"
          skip_metric_validation = false
          dimension = [
            {
              name     = "ResponseType"
              operator = "Include"
              values   = ["AuthenticationError", "AuthorizationError", "NetworkError", "ClientOtherNetwork"]
            }
          ]
        }
      ]
    },
    sa_dl_usedcapacity = {
      name            = "ar-${local.name_base}-${module.storage_account["dl"].name}usedcapacity"
      scopes          = [module.storage_account["dl"].id]
      description     = "Storage Account ${module.storage_account["dl"].name} used capacity is more than 120 TiB. Please check whether Storage account can be cleaned up or limit should be increased if triggered."
      auto_mitigate   = true
      frequency       = "PT30M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "UsedCapacity"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = var.SA_DL_STORAGE_USAGE_ALERT * (pow(1024, 3))
          skip_metric_validation = false
        }
      ]
    },
    sa_temp_availability = {
      name            = "ar-${local.name_base}-${module.storage_account["temp"].name}availability"
      scopes          = [module.storage_account["temp"].id]
      description     = "Storage Account ${module.storage_account["temp"].name} availability issues. Please check whether Storage account is available and contact Microsoft support for assistance if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Availability"
          aggregation            = "Average"
          operator               = "LessThan"
          threshold              = 100
          skip_metric_validation = false
        }
      ]
    },
    sa_temp_transaction_errors = {
      name            = "ar-${local.name_base}-${module.storage_account["temp"].name}transactions"
      scopes          = [module.storage_account["temp"].id]
      description     = "Storage Account ${module.storage_account["temp"].name} transaction issues detection. Please check whether Storage account is available and operating properly if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      dynamic_criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Transactions"
          aggregation            = "Total"
          operator               = "GreaterThan"
          alert_sensitivity      = "High"
          skip_metric_validation = false
          dimension = [
            {
              name     = "ResponseType"
              operator = "Include"
              values   = ["AuthenticationError", "AuthorizationError", "NetworkError", "ClientOtherNetwork"]
            }
          ]
        }
      ]
    },
    sa_temp_usedcapacity = {
      name            = "ar-${local.name_base}-${module.storage_account["temp"].name}usedcapacity"
      scopes          = [module.storage_account["temp"].id]
      description     = "Storage Account ${module.storage_account["temp"].name} used capacity is more than 120 TiB. Please check whether Storage account can be cleaned up or limit should be increased if triggered."
      auto_mitigate   = true
      frequency       = "PT30M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "UsedCapacity"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = var.SA_TEMP_STORAGE_USAGE_ALERT * (pow(1024, 3))
          skip_metric_validation = false
        }
      ]
    },
    sa_airflow_availability = {
      name            = "ar-${local.name_base}-${module.storage_account_sas["airflow"].name}availability"
      scopes          = [module.storage_account_sas["airflow"].id]
      description     = "Storage Account ${module.storage_account_sas["airflow"].name} availability issues. Please check whether Storage account is available and contact Microsoft support for assistance if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Availability"
          aggregation            = "Average"
          operator               = "LessThan"
          threshold              = 100
          skip_metric_validation = false
        }
      ]
    },
    sa_airflow_transaction_errors = {
      name            = "ar-${local.name_base}-${module.storage_account_sas["airflow"].name}transactions"
      scopes          = [module.storage_account_sas["airflow"].id]
      description     = "Storage Account ${module.storage_account_sas["airflow"].name} transaction issues detection. Please check whether Storage account is available and operating properly if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      dynamic_criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Transactions"
          aggregation            = "Total"
          operator               = "GreaterThan"
          alert_sensitivity      = "High"
          skip_metric_validation = false
          dimension = [
            {
              name     = "ResponseType"
              operator = "Include"
              values   = ["AuthenticationError", "AuthorizationError", "NetworkError", "ClientOtherNetwork"]
            }
          ]
        }
      ]
    },
    sa_airflow_usedcapacity = {
      name            = "ar-${local.name_base}-${module.storage_account_sas["airflow"].name}usedcapacity"
      scopes          = [module.storage_account_sas["airflow"].id]
      description     = "Storage Account ${module.storage_account_sas["airflow"].name} used capacity is more than 120 TiB. Please check whether Storage account can be cleaned up or limit should be increased if triggered."
      auto_mitigate   = true
      frequency       = "PT30M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "UsedCapacity"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = var.SA_AIRFLOW_STORAGE_USAGE_ALERT * (pow(1024, 3))
          skip_metric_validation = false
        }
      ]
    },
    sa_law_availability = {
      name            = "ar-${local.name_base}-${module.storage_account["law"].name}availability"
      scopes          = [module.storage_account["law"].id]
      description     = "Storage Account ${module.storage_account["law"].name} availability issues. Please check whether Storage account is available and contact Microsoft support for assistance if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Availability"
          aggregation            = "Average"
          operator               = "LessThan"
          threshold              = 100
          skip_metric_validation = false
        }
      ]
    },
    sa_law_transaction_errors = {
      name            = "ar-${local.name_base}-${module.storage_account["law"].name}transactions"
      scopes          = [module.storage_account["law"].id]
      description     = "Storage Account ${module.storage_account["law"].name} transaction issues detection. Please check whether Storage account is available and operating properly if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      dynamic_criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "Transactions"
          aggregation            = "Total"
          operator               = "GreaterThan"
          alert_sensitivity      = "High"
          skip_metric_validation = false
          dimension = [
            {
              name     = "ResponseType"
              operator = "Include"
              values   = ["AuthenticationError", "AuthorizationError", "NetworkError", "ClientOtherNetwork"]
            }
          ]
        }
      ]
    },
    sa_law_usedcapacity = {
      name            = "ar-${local.name_base}-${module.storage_account["law"].name}usedcapacity"
      scopes          = [module.storage_account["law"].id]
      description     = "Storage Account ${module.storage_account["law"].name} used capacity is more than 120 TiB. Please check whether Storage account can be cleaned up or limit should be increased if triggered."
      auto_mitigate   = true
      frequency       = "PT30M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.Storage/storageAccounts"
          metric_name            = "UsedCapacity"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = var.SA_LAW_STORAGE_USAGE_ALERT * (pow(1024, 3))
          skip_metric_validation = false
        }
      ]
    },
    psql_cpu_used = {
      name            = "ar-${local.name_base}-psqlcpuused"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} CPU usage alert. If triggered, please consider scaling up server or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "cpu_percent"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    psql_memory_used = {
      name            = "ar-${local.name_base}-psqlmemoryused"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} memory usage alert. If triggered, please consider scaling up server or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "memory_percent"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    psql_storage_used = {
      name            = "ar-${local.name_base}-psqlstorageused"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} storage usage alert. If triggered, please consider scaling up server or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "storage_percent"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 90
          skip_metric_validation = false
        }
      ]
    },
    psql_disk_iops_used = {
      name            = "ar-${local.name_base}-psqldiskiopsused"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} disk IOPS alert. If triggered, please consider scaling up server or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "disk_iops_consumed_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    psql_active_connections = {
      name            = "ar-${local.name_base}-psqlactiveconnections"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} active connections alert. If triggered, please consider reconfigure max connections or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "active_connections"
          aggregation            = "Maximum"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    psql_is_alive = {
      name            = "ar-${local.name_base}-psqlisalive"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} alive status alert. If triggered, please consider checking database server."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "is_db_alive"
          aggregation            = "Average"
          operator               = "LessThan"
          threshold              = 1
          skip_metric_validation = false
        }
      ]
    },
    psql_deadlocks = {
      name            = "ar-${local.name_base}-psqldeadlocks"
      scopes          = [module.postgresql.postgresql_server_id]
      description     = "PostgreSQL Database Server ${local.postgresql.name} deadlocks alert. If triggered, please check database for deadlocks and resolve them."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name            = "deadlocks"
          aggregation            = "Total"
          operator               = "GreaterThan"
          threshold              = 0
          skip_metric_validation = false
        }
      ]
    },
    aks_main_cpu_used = {
      name            = "ar-${local.name_base}-aksmaincpuused"
      scopes          = [module.aks["main"].aks_cluster_id]
      description     = "AKS Main cluster CPU usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_cpu_usage_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 85
          skip_metric_validation = false
        }
      ]
    },
    aks_main_memory_used = {
      name            = "ar-${local.name_base}-aksmainmemoryused"
      scopes          = [module.aks["main"].aks_cluster_id]
      description     = "AKS Main cluster memory usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_memory_working_set_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    aks_main_storage_used = {
      name            = "ar-${local.name_base}-aksmainstorageused"
      scopes          = [module.aks["main"].aks_cluster_id]
      description     = "AKS Main cluster storage usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_disk_usage_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    aks_main_cluster_health = {
      name            = "ar-${local.name_base}-aksmainclusterhealth"
      scopes          = [module.aks["main"].aks_cluster_id]
      description     = "AKS Main cluster cluster health alert. If triggered, please check Kubernetes cluster."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "cluster_autoscaler_cluster_safe_to_autoscale"
          aggregation            = "Total"
          operator               = "LessThan"
          threshold              = 1
          skip_metric_validation = false
        }
      ]
    },
    aks_main_failed_pods = {
      name            = "ar-${local.name_base}-aksmainfailedpods"
      scopes          = [module.aks["main"].aks_cluster_id]
      description     = "AKS Main cluster failed or unknown pods status alert. If triggered, please investigate failure status of pod."
      auto_mitigate   = true
      frequency       = "PT5M"
      window_size     = "PT15M"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "kube_pod_status_phase"
          aggregation            = "Total"
          operator               = "GreaterThan"
          threshold              = 0
          skip_metric_validation = false
          dimension = [
            {
              name     = "phase"
              operator = "Include"
              values   = ["Unknown", "Failed"]
            }
          ]
        }
      ]
    },
    aks_devops_cpu_used = {
      name            = "ar-${local.name_base}-aksdevopscpuused"
      scopes          = [data.terraform_remote_state.enablers.outputs.aks_devops_id]
      description     = "AKS DevOps cluster CPU usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_cpu_usage_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 85
          skip_metric_validation = false
        }
      ]
    },
    aks_devops_memory_used = {
      name            = "ar-${local.name_base}-aksdevopsmemoryused"
      scopes          = [data.terraform_remote_state.enablers.outputs.aks_devops_id]
      description     = "AKS DevOps cluster memory usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_memory_working_set_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    aks_devops_storage_used = {
      name            = "ar-${local.name_base}-aksdevopsstorageused"
      scopes          = [data.terraform_remote_state.enablers.outputs.aks_devops_id]
      description     = "AKS DevOps cluster storage usage alert. If triggered, please consider scaling up Kubernetes cluster or decrease load on it."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "node_disk_usage_percentage"
          aggregation            = "Average"
          operator               = "GreaterThanOrEqual"
          threshold              = 80
          skip_metric_validation = false
        }
      ]
    },
    aks_devops_failed_pods = {
      name            = "ar-${local.name_base}-aksdevopsfailedpods"
      scopes          = [data.terraform_remote_state.enablers.outputs.aks_devops_id]
      description     = "AKS DevOps cluster failed or unknown pods status alert. If triggered, please investigate failure status of pod."
      auto_mitigate   = true
      frequency       = "PT5M"
      window_size     = "PT15M"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "kube_pod_status_phase"
          aggregation            = "Total"
          operator               = "GreaterThan"
          threshold              = 0
          skip_metric_validation = false
          dimension = [
            {
              name     = "phase"
              operator = "Include"
              values   = ["Unknown", "Failed"]
            }
          ]
        }
      ]
    },
    aks_devops_cluster_health = {
      name            = "ar-${local.name_base}-aksdevopsclusterhealth"
      scopes          = [data.terraform_remote_state.enablers.outputs.aks_devops_id]
      description     = "AKS DevOps cluster cluster health alert. If triggered, please check Kubernetes cluster."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 1
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      criterias = [
        {
          metric_namespace       = "Microsoft.ContainerService/managedClusters"
          metric_name            = "cluster_autoscaler_cluster_safe_to_autoscale"
          aggregation            = "Total"
          operator               = "LessThan"
          threshold              = 1
          skip_metric_validation = false
        }
      ]
    },
    kv_main_api_errors = {
      name            = "ar-${local.name_base}-kvmaintransactions"
      scopes          = [module.keyvault["main"].key_vault_id]
      description     = "Key Vault API 4xx errors detection. Please check whether Key Vault is available, operating properly and detect source of issue if triggered."
      auto_mitigate   = true
      frequency       = "PT15M"
      window_size     = "PT1H"
      severity        = 2
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
      dynamic_criterias = [
        {
          metric_namespace       = "Microsoft.KeyVault/vaults"
          metric_name            = "ServiceApiResult"
          aggregation            = "Count"
          operator               = "GreaterThan"
          alert_sensitivity      = "High"
          skip_metric_validation = false
          dimension = [
            {
              name     = "StatusCodeClass"
              operator = "Include"
              values   = ["4xx"]
            }
          ]
        }
      ]
    }
  }

  resource_health_alerts = {
    sa = {
      resource_name   = "ar-${local.name_base}-saresourceshealth"
      scopes          = concat([for sa in module.storage_account : sa.id], [for sa in module.storage_account_sas : sa.id])
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
    },
    aks = {
      resource_name   = "ar-${local.name_base}-aksresourceshealth"
      scopes          = [module.aks["main"].aks_cluster_id, data.terraform_remote_state.enablers.outputs.aks_devops_id]
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
    },
    kv = {
      resource_name   = "ar-${local.name_base}-kvresourceshealth"
      scopes          = [module.keyvault["main"].key_vault_id]
      action_group_id = azurerm_monitor_action_group.action_group["devops_internal_dev"].id
    }
  }
}