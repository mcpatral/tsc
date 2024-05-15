locals {
  mi_sa_tags = {}

  # TODO: There were 2 SA for AML - second SA was removed. Need to check whether we need second SA or not.
  # Storage Blob Data Owner is necessary, among other tasks, to set up acls at the container level for adls storage accounts
  storage_account = {
    public_network_access_enabled   = false
    default_network_rule            = "Deny"
    diagnostic_set_name             = "ds-logs-${local.name_base}-storage"
    diagnostic_set_id               = var.CENTRAL_LAW_ID != null ? var.CENTRAL_LAW_ID : local.enablers_tfstate_output.law_main_id
    blob_delete_retention_days      = 7
    container_delete_retention_days = 7
    authorized_ips = toset([
      for ip_address in local.authorized_ips : replace(ip_address, "/32", "")
    ])
    management_lock_common = {
      name  = "lock-${local.name_base}"
      notes = "Locked because it's needed by a third-party."
    }
    objects = {
      "dl" = {
        account_kind                = "StorageV2"
        is_hns_enabled              = true
        replication_type            = var.PAIR_PAAS == true ? "RAGRS" : "LRS"
        account_tier                = "Standard"
        shared_access_key_enabled   = false
        nfsv3_enabled               = false
        subnet_service_endpoints    = null
        create_customer_managed_key = true
        traffic_bypass              = ["None"]
        tags = {
          DataClassification = "Restricted"
        }
        management_lock = {
          enabled    = false
          lock_level = "CanNotDelete"
        }
        role_mapping = {
          "dbac_exloc_contrib" = {
            principal_id         = azurerm_databricks_access_connector.connector["dbac-${local.name_base}-extloc"].identity[0].principal_id
            role_definition_name = "Storage Blob Data Contributor"
          }
          "datascientist_contrib" = {
            principal_id         = var.DATASCIENTIST_GROUP_ID
            principal_type       = "Group"
            role_definition_name = "Storage Blob Data Contributor"
          }
          "spn_owner" = {
            principal_id         = data.azurerm_client_config.current.object_id
            role_definition_name = "Storage Blob Data Owner"
          }
          "aks_contrib" = {
            principal_id         = module.aks["main"].aks_kubelet_identity_object_id
            role_definition_name = "Storage Blob Data Contributor"
          }
        }
        test_role_mapping = {
          "cff2_contrib" = {
            principal_id         = var.SA_CFF2_SPN_OBJECT_ID
            role_definition_name = "Storage Blob Data Contributor"
          }
        }
        containers = {
          landing = {
            include_in_management_policy = true
            directories = {
              "cff1_files" = {
                acls = {
                  txbobjectid = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "cff2_files" = {
                acls = {
                  txbobjectid = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "currency_rates" = {
                acls = {
                  txbobjectid = [var.TXB_OBJECT_ID, "rwx"]
                }
              }
              "error_files" = {}
            }
          }
          bronze = {
            include_in_management_policy = true
            parent_directories = {
              "data" = {}
            }
            directories = {
              "data/system_1136" = {}
              "data/system_1137" = {}
              "data/system_2071" = {}
              "data/system_4041" = {}
              "data/system_7006" = {}
              "data/system_7008" = {}
              "data/system_7010" = {}
              "data/system_7023" = {}
              "data/system_9003" = {}
              "data/system_9005" = {}
              "data/system_9014" = {}
              "data/system_9023" = {}
              "data/system_9995" = {}
              "data/system_9996" = {}
              "data/system_9997" = {}
              "data/system_9998" = {}
              "data/system_9999" = {}
            }
          }
          silver = {
            include_in_management_policy = false
            directories                  = {}
          }
        }
      }
      # "aml" = {
      #   account_kind                      = "StorageV2"
      #   is_hns_enabled                    = true
      #   replication_type                  = var.PAIR_PAAS == true ? "ZRS" : "LRS" # TODO NO GEOREPLICATION IN PLACE, PLEASE REVIEW
      #   account_tier                      = "Standard"
      #   shared_access_key_enabled         = true
      #   nfsv3_enabled                     = true
      #   subnet_service_endpoints          = null
      #   create_customer_managed_key       = false
      #   management_lock = {
      #     enabled    = false
      #     lock_level = "CanNotDelete"
      #   }
      # }
      # "vertica" = {
      #   account_kind                      = "StorageV2"
      #   is_hns_enabled                    = false
      #   replication_type                  = var.PAIR_PAAS == true ? "RAGRS" : "LRS"
      #   account_tier                      = "Standard"
      #   shared_access_key_enabled         = false
      #   nfsv3_enabled                     = false
      # create_customer_managed_key       = true
      #   management_lock = {
      #     enabled    = true
      #     lock_level = "CanNotDelete"
      #   }
      #   subnet_service_endpoints = [
      #     local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"],
      #     local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"],
      #     local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-devops-agents"]
      #   ]
      #   role_mapping = {
      #     "aks_contrib" = {
      #       principal_id         = module.aks["main"].aks_kubelet_identity_object_id
      #       role_definition_name = "Storage Blob Data Contributor"
      #     }
      #   }
      #   containers = {
      #     "gaia${var.ENVIRONMENT_TYPE}" = {
      #       include_in_management_policy = false
      #       directories                  = {}
      #     }
      #   }
      # }
      "temp" = {
        account_kind                = "StorageV2"
        is_hns_enabled              = true
        replication_type            = var.PAIR_PAAS == true ? "RAGRS" : "LRS"
        account_tier                = "Standard"
        shared_access_key_enabled   = false
        nfsv3_enabled               = false
        subnet_service_endpoints    = null
        create_customer_managed_key = true
        traffic_bypass              = ["None"]
        tags = {
          DataClassification = "Restricted"
        }
        management_lock = {
          enabled    = false
          lock_level = "CanNotDelete"
        }
        role_mapping = {
          "dbac_extloc_contrib" = {
            # Required for Vertica to read and write data to Temp SA
            principal_id         = azurerm_databricks_access_connector.connector["dbac-${local.name_base}-extloc"].identity[0].principal_id
            role_definition_name = "Storage Blob Data Contributor"
          }
          "aks_contrib" = {
            principal_id         = module.aks["main"].aks_kubelet_identity_object_id
            role_definition_name = "Storage Blob Data Contributor"
          }
          "spn_owner" = {
            principal_id         = data.azurerm_client_config.current.object_id
            role_definition_name = "Storage Blob Data Owner"
          }
        }
        test_role_mapping = {}
        containers = {
          temporary = {
            include_in_management_policy = true
            directories = {
              "tmp" = {}
            }
          }
        }
      }
      "airflow" = {
        account_kind                = "StorageV2"
        is_hns_enabled              = true
        replication_type            = var.PAIR_PAAS == true ? "ZRS" : "LRS" # TODO NO GEOREPLICATION IN PLACE, PLEASE REVIEW
        account_tier                = "Standard"
        shared_access_key_enabled   = true
        nfsv3_enabled               = true
        create_customer_managed_key = true
        traffic_bypass              = ["AzureServices"]
        tags                        = {}
        management_lock = {
          enabled    = false
          lock_level = "CanNotDelete"
        }
        # GRS, GZRS, and RA-GRS redundancy options aren't supported when you create an NFS 3.0 storage account.
        # https://learn.microsoft.com/en-us/azure/storage/blobs/network-file-system-protocol-known-issues
        # Personal notes: the reality is that nfsv3_enabled can be true only for LRS and ZRS. I have already tried RAGZRS without success.
        # Misleading official Terraform notes: nfsv3_enabled can only be true when account_tier is Standard and account_kind is StorageV2, or account_tier is Premium and account_kind is BlockBlobStorage. Additionally, the is_hns_enabled is true and account_replication_type must be LRS or RAGRS.
        # Other documentation:
        # https://github.com/hashicorp/terraform-provider-azurerm/issues/13933
        # https://learn.microsoft.com/en-us/azure/storage/blobs/network-file-system-protocol-support-how-to
        # TODO review updates on the following Microsoft community idea
        # https://feedback.azure.com/d365community/idea/11e5cfd1-f861-ee11-a81c-000d3ae5ae95
        subnet_service_endpoints = [
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"],
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"],
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-devops-agents"]
        ]
        role_mapping = {
          #only non-dynamic content
          "spn_owner" = {
            principal_id         = data.azurerm_client_config.current.object_id
            role_definition_name = "Storage Blob Data Owner"
          }
        }
        test_role_mapping = {}
        containers = {
          dags = {
            include_in_management_policy = false
            directories                  = {}
          }
          logs = {
            include_in_management_policy = true
            directories                  = {}
          }
        }
      }
      "law" = {
        account_kind                = "StorageV2"
        is_hns_enabled              = true
        replication_type            = var.PAIR_PAAS == true ? "RAGRS" : "LRS"
        account_tier                = "Standard"
        shared_access_key_enabled   = false
        nfsv3_enabled               = true
        create_customer_managed_key = true
        traffic_bypass              = ["AzureServices"]
        tags                        = {}
        management_lock = {
          enabled    = false
          lock_level = "CanNotDelete"
        }
        subnet_service_endpoints = [
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-endpoints"],
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-aks-primary"],
          local.enablers_tfstate_output.networks_vnet_subnets["subnet-${local.name_base}-devops-agents"]
        ]
        role_mapping = {
          "spn_owner" = {
            principal_id         = data.azurerm_client_config.current.object_id
            role_definition_name = "Storage Blob Data Owner"
          }
        }
        test_role_mapping = {}
        containers = {
          "law${var.ENVIRONMENT_TYPE}" = {
            include_in_management_policy = false
            directories                  = {}
          }
        }
      }
    }
  }
}