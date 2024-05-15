#High availability in Azure Database for PostgreSQL - Flexible Server, which includes:

# A) Availability zones. Flexible Server supports the following high availability configurations: 
# A.1) Zone-redundant: deploys a standby replica in a different zone with automatic failover capability.
# A.2) Zonal models: A standby replica server is automatically provisioned and managed in the same availability zone.
#HA is not supported for Burstable SKUs, such as B_Standard_B1ms.

# B) Cross-region resiliency with disaster recovery. There are two options:
# B.1) Geo-redundant backup and restore: provide the ability to restore your server in a different region in the event of a disaster. 
# When the server is configured with geo-redundant backup, the backup data and transaction logs are copied to the paired region asynchronously through storage replication.
# If your server is configured with geo-redundant backup, you can perform geo-restore in the paired region. 
# A new server is provisioned and recovered to the last available data that was copied to this region.
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-restore-server-portal#perform-geo-restore
# Currently, PITR of geo-redundant backups is not available.
#https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-backup-restore#geo-redundant-backup-and-restore
# B.2) Cross region read replicas: In the event of region failure you can perform disaster recovery operation by promoting your read replica to be a standalone read-writeable server. 
# Read replicas are updated asynchronously using PostgreSQL's physical replication technology, and may lag the primary. 
# Read replicas are supported in general purpose and memory optimized compute tiers.

#https://learn.microsoft.com/en-us/azure/reliability/reliability-postgresql-flexible-server
# Note: In this code, I will be using geo replication.
#https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/

#TODO use Terraform module resource when this issue is solved
#https://github.com/hashicorp/terraform-provider-azurerm/issues/16811
resource "null_resource" "geo_replicated_new_postgresql_server" {
  triggers = {
    psql_name            = local.postgresql.name
    rg_name              = local.enablers_tfstate_output.resource_group_name
    location             = var.PAIR_LOCATION
    zone                 = var.POSTGRES_ZONE
    source_server_id     = local.postgresql.source_server_id
    delegated_subnet_id  = local.postgresql.delegated_subnet_id
    private_dns_zone_id  = local.postgresql.private_dns_zone_id
    geo_redundant_backup = local.postgresql.geo_redundant_backup
  }
  provisioner "local-exec" {
    when    = create
    command = <<EOT
az postgres flexible-server geo-restore --resource-group ${self.triggers.rg_name} --name ${self.triggers.psql_name} --source-server ${self.triggers.source_server_id} --subnet ${self.triggers.delegated_subnet_id} --private-dns-zone ${self.triggers.private_dns_zone_id} --location ${self.triggers.location} --geo-redundant-backup ${self.triggers.geo_redundant_backup} --zone ${self.triggers.zone}
EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
az postgres flexible-server delete --resource-group ${self.triggers.rg_name} --name ${self.triggers.psql_name} --yes
EOT
  }
}
