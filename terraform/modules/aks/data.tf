data "azurerm_public_ip" "aks_pip" {
  count               = var.network_outbound_type == "loadBalancer" ? 1 : 0
  name                = split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[8]
  resource_group_name = split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[4]
}
