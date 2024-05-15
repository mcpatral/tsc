output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_resource_group_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "aks_cluster_node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_admin" {
  value = azurerm_kubernetes_cluster.aks.linux_profile.0.admin_username
}

output "private_ssh_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "public_ssh_key" {
  value = tls_private_key.ssh.public_key_pem
}

output "public_ssh_key_openssh" {
  value = tls_private_key.ssh.public_key_openssh
}

output "aks_cluster_fqdn" {
  value = var.private_cluster_enabled ? azurerm_kubernetes_cluster.aks.private_fqdn : azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_cluster_pods_cidr" {
  value = azurerm_kubernetes_cluster.aks.network_profile.0.pod_cidr
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

output "aks_kubelet_identity_client_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity.0.client_id
}

output "aks_outbound_public_ip" {
  value = var.network_outbound_type == "loadBalancer" ? data.azurerm_public_ip.aks_pip.0.ip_address : null
}