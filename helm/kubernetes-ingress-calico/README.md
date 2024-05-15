# Kubernetes Ingress Controller chart

This Chart is Umbrella chart for [ingress-nginx](https://github.com/kubernetes/ingress-nginx) ingress controller chart. Apart of Kubernetes Ingress Controller installation, it also creates Calico rules for connections to its workloads.

## Calico rules

This chart contains only Calico rules and doesn't have any Open Service Mesh rules, because Ingress Controller is Entrypoint to the Service Mesh network and it doesn't have Envoy proxy as sidecar container which will apply Open Service Mesh rules. It is intended by design of Open Service Mesh.

Chart contains two files - `calico-allow-rules.yml` and `calico-deny-all.yml` with templates for Calico rules.

### Deny All rules

First of all, `calico-deny-all.yml` template contains `ingress-nginx-deny-all` set of rules. 

It has rule that blocks all inbound and outbound TCP traffic to/from all resources in `ingress-controller` namespace. Also, it has rule to log all packets that were blocked to `syslog` of Kubernetes Node. 

This set of rules has `100` order which is considered as the lowest priority rule and it is executed only when traffic doesn't meet any other rule.

### Ingress allow rules

Secondly, `calico-allow-rules.yml` template contains `ingress-nginx-allow-rules` set of rules.

Ports `80` and `443` can accept connections from `168.63.129.16/32` CIDR. This is Azure static IP address which is used for different Azure services. In case of Ingress Controller, this IP performs healthchecks defined on Azure Load Balancer level and checks whether Ingress Controller alive and Load Balancer service can route traffic to it's pods. Without those, Load Balancer won't work and users won't be able to connect to the web applications deployed in cluster.

Also, ports `80`, `443`, `8443`, `10254` are allowed for inbound connections from Kubernetes API, Kubernetes nodes network and Kubernetes pods (Calico CNI) networks. This is required to ensure proper work of Ingress Controller load balancing, admission webhooks and monitoring endpoints for Prometheus and Grafana.

- `80`, `443` - Ingress Controller listening ports
- `8443` - Admission Webhook listening port which is required for Kubernetes API to validate applied configuration of `Ingress` objects
- `10254` - Monitoring port for Prometheus metrics

### Egress allow rules

It is allowed all traffic from Ingress Controller pods to the Kubernetes Nodes and Pods to ensure proper work of controller. Ports of Ingress and Services objects might be different and we won't to ensure that everything is working properly.

Also, we are allowing port `53` under `UDP` protocol to ensure proper work of DNS service on Ingress Controller pods. This is required to ensure proper work of Ingress Controller's load balancing.

Finally, we are allowing connections on port `443` to the Internal and External endpoints of Kubernetes API. This is required to ensure proper work of Kubernetes probes, Admission webhooks and general work of Ingress Controller workloads on Kubernetes level.
