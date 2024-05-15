locals {
  storage_account = {
    public_network_access_enabled   = false
    default_network_rule            = "Deny"
    traffic_bypass                  = ["AzureServices"]
    diagnostic_set_name             = "ds-logs-${local.name_base}-storage"
    diagnostic_set_id               = var.PAIR_CENTRAL_LAW_ID != null ? var.PAIR_CENTRAL_LAW_ID : local.enablers_tfstate_output.law_main_id
    blob_delete_retention_days      = 7
    container_delete_retention_days = 7
    authorized_ips = toset([
      for ip_address in local.authorized_ips : replace(ip_address, "/32", "")
    ])
    storage_management_policy_common = {
      blob_tier_to_cool_after_days_since_modification_greater_than = 180
      blob_delete_after_days_since_modification_greater_than       = 3650
      snapshot_delete_after_days_since_creation_greater_than       = 3650
    }
    management_lock_common = {
      name  = "lock-${local.name_base}"
      notes = "Locked because it's needed by a third-party."
    }
    objects = {
      # "aml" = {
      #   account_kind                      = "StorageV2"
      #   is_hns_enabled                    = true
      #   replication_type                  = "ZRS"
      #   account_tier                      = "Standard"
      #   shared_access_key_enabled         = true
      #   nfsv3_enabled                     = true
      #   storage_management_policy_enabled = true
      #   management_lock = {
      #     enabled    = false
      #     lock_level = "CanNotDelete"
      #   }
      # }
      "airflow" = {
        account_kind                      = "StorageV2"
        is_hns_enabled                    = true
        replication_type                  = var.PAIR_PAAS == true ? "ZRS" : "LRS" # TODO NO GEOREPLICATION IN PLACE, PLEASE REVIEW
        account_tier                      = "Standard"
        shared_access_key_enabled         = true
        nfsv3_enabled                     = true
        storage_management_policy_enabled = true
        create_customer_managed_key       = true
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
    }
  }
}