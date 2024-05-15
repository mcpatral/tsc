# Vertica DB chart

This chart installs Vertica CRDs based resources (VerticaDB, EventTrigger), initialize database creation in Storage account and creates subclusters with proper services. Also, this chart contains Calico allow rules for inbound and outbound connections for subcluster. This chart has prerequisite that `vertica-operator` chart should be pre-installed in the same namespace where this chart will be installed.

# Calico rules

Chart has templates for Calico rules. All template files that starts with `calico-` contains Calico TCP/IP rules with namespace, vnets and/or ports that allowed.

## Ingress rules

Template `calico-allow-rules.yml` contains 4 ingress rules that allow inbound connections to the workload resources of chart.

First rule allows connections on ports `5433, 8443, 5444` from Kubernetes cluster internal API IP address (`10.0.0.1`), AKS nodes subnet and `168.63.129.16` IP address.

Internal API must be allowed to ensure proper work of admission webhooks which are listening on port `8443` and probes.

AKS nodes subnet needs to be allowed separately, because this subnet hosts all Load Balancers that are created by AKS for its Service objects. Basically, this ensures proper work of Service and makes Vertica available for "out of Kubernetes" connections.

Finally, `168.63.129.16` should be allowed following Microsoft recommendations and for ensuring proper work of Load Balancer service. Please check [Microsoft official documentation](https://learn.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16) for more details. 

Second rule allowing connections on port `5433` from `airflow` namespace workload resources with `airflow` service account assigned. This ensures proper connection between Airflow and Vertica.

Finally, we are allowing all TCP and UDP inbound traffic between pods in `vertica` namespace with Vertica operator service account assigned. This is required for proper work of Vertica subclusters and operator. Vertica uses random port ranges for connections between workload resources and we can't specify exact ports to be used unfortunately.

## Egress rules

The only outbound rule we have - allow all TCP and UDP outbound traffic between pods in `vertica` namespace with Vertica operator service account assigned. Same reason as for inbound rules. Vertica uses random port ranges for connections between workload resources and we can't specify exact ports to be used unfortunately.