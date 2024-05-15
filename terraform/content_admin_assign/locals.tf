locals {
  name_base         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash = replace(local.name_base, "-", "")

  backend_rg_name        = "rg-${local.name_base}-state"
  backend_sa_name        = "sa${local.name_base_no_dash}tfstate"
  backend_container_name = "${var.ENVIRONMENT_TYPE}tfstate"
  storage_use_azuread    = true
  use_azuread_auth       = true

  db_workspace_host = data.terraform_remote_state.infrastructure.outputs.db_workspace_host

}
