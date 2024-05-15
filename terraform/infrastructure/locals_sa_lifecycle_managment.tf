locals {
  # Map of storage accounts IDs where lifecycle managment rules enabled
  storage_accounts_lifecycle_managment = {
    dl   = try(module.storage_account["dl"].id, module.storage_account_sas["dl"].id)
    temp = try(module.storage_account["temp"].id, module.storage_account_sas["temp"].id)
  }

  lifecycle_managment_rules = {
    dl = [
      {
        name    = "lifecycle_policy_rule_bronze_currency_rates"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/currency_rates/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_1136"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_1136/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_1137"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_1137/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_2071"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_2071/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_4041"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_4041/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_7006"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_7006/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_7008"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_7008/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_7010"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_7010/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_7023"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_7023/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9003"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9003/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9005"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9005/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9014"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9014/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9023"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9023/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9995"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9995/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9996"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9996/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9997"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9997/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9998"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9998/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_bronze_system_9999"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["bronze/data/system_9999/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 730
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_landing_cff1_files"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["landing/cff1_files/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 30
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_landing_cff2_files"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["landing/cff2_files/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 30
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_landing_currency_rates"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["landing/currency_rates/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 30
          }
        }
      },
      {
        name    = "lifecycle_policy_rule_landing_error_files"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["landing/error_files/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 30
          }
        }
      },
      # Add more rules for dl here
    ],
    temp = [
      {
        name    = "lifecycle_policy_rule_landing_temporary"
        enabled = true
        type    = "Lifecycle"
        filters = [
          {
            prefix_match = ["temporary/tmp/"]
            blob_types   = ["blockBlob"]
          },
        ]
        actions = {
          base_blob = {
            delete_after_days = 30
          }
        }
      },
      # Add more rules for temp sa here
    ],
    # Add more rules for other storage accounts here
  }
}