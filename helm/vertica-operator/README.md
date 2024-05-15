# Vertica Operator umbrella chart

This Helm chart is umbrella chart which is using [Vertica DB Operator chart](https://github.com/vertica/vertica-kubernetes/tree/v1.11.1/helm-charts/verticadb-operator) as a base chart for Vertica operator deployment and creates Calico rules for inbound and outbound connections inside and outside Kubernetes cluster.

# Calico rules

Chart has templates for Calico rules. These rules applies not only to Vertica operator pods, but to **ALL** workload resources that are deployed in the chart namespace. All template files that starts with `calico-` contains Calico TCP/IP rules with namespace, vnets and/or ports that allowed.

## Deny all rule

First of all, this chart has `deny-all` rule that denies all inbound and outbound connections to all `vertica` namespace workload resources. Also, it logs all denies to the `syslog` of AKS nodes for further investigation.

## Ingress rules

Chart contains only one ingress rule for inbound connections allowing inbound connections on ports `8443, 9443` from Kubernetes API internal IP address (`10.0.0.1`) and from pods network (Calico CNI) for Vertica Operator pods only.

Internal API must be allowed to ensure proper work of admission webhooks which are listening on port `9443` and probes.

Pods network is whitelisted fully as well for proper work of admission webhooks and also for metrics collection by Prometheus which scrap data from port `8443`.

## Egress rules

Multiple egress rules are specified inside Chart for outbound connections.

First of all, we are allowing all TCP and UDP outbound traffic between pods in `vertica` namespace with Vertica operator service account assigned. This is required for proper work of Vertica subclusters and operator. Please note, that only outbound traffic needs to be whitelisted. It means that only Operator connects Subclusters, but Subclusters don't connect to Operator. Vertica uses random port ranges for connections between workload resources and we can't specify exact ports to be used unfortunately.

Next rules are applied to all pods in `vertica` namespace.

We are allowing all TCP connections and UDP connections to port `53` to `kube-system` namespace to ensure proper work of Kubernetes cluster and its internal services (such as `kube-dns`).

Also, we are allowing connections on `443` port to the Kubernetes API (both Internal and External IP addresses) to ensure proper work of Kubernetes probes and webhooks, and to Endpoints subnet to ensure that workload resources can connect to the private endpoints of Azure services. Connection to Endpoints subnet is needed for connection between Vertica and Storage account which is Communal storage of Vertica DB.

Finally, we are allowing connections to the `169.254.169.254` on port `80` per Microsoft recommendation. Please note that this IP address is reserved on Azure VNet level and accessible only from nodes in the VNet (including Kubernetes nodes). Connection to that IP address never leaves the host and happens internally. If you need more information, please refer to [official Microsoft documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service).

# Self signed certificates generation

To generate TLS certificates for Vertica operator, follow these steps below. Please notice that these steps were executed on Linux Ubuntu 20.04 and some steps may differ on different operating systems.

1. Generate CA certificates and keys:
    ```
    mkdir CA
    openssl req -x509 -sha256 -days 1825 -nodes -newkey rsa:2048 -subj "/CN=ca.vertica.svc/C=LV/L=Riga" -keyout CA/rootCA.key -out CA/rootCA.crt
    ```

2. Generate Vertica keys for HTTP and Internode TCP connections
    ```
    openssl genrsa -out intervertica.key 2048
    openssl genrsa -out httpvertica.key 2048
    ```

3. Create Certificate signing request configuration file - httpcsr.conf.
Please note **\*vertica-namespace\*** value that needs to be replaced to actual namespace value defined in your variable group.
    ```
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn

    [ dn ]
    C = LV
    L = Riga
    O = Intrum Global Technologies
    OU = IGT Dev
    CN = verticadb-operator-webhook-service.*vertica-namespace*.svc.cluster.local

    [ req_ext ]
    subjectAltName = @alt_names

    [ alt_names ]
    DNS.1 = verticadb-operator-webhook-service.*vertica-namespace*.svc.cluster.local
    DNS.2 = verticadb-operator-webhook-service.*vertica-namespace*.svc
    ```

4. Create Certificate signing request configuration file - intercsr.conf.
Please note **\*vertica-namespace\*** value that needs to be replaced to actual namespace value defined in your variable group.
Value **\*environment-name\*** needs to be replaced to your environment name (for example - `kfr01`).
    ```
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn

    [ dn ]
    C = LV
    L = Riga
    O = Intrum Global Technologies
    OU = IGT Dev
    CN = vertica-db-vertica-connections.*vertica-namespace*.svc.cluster.local

    [ req_ext ]
    subjectAltName = @alt_names
    extendedKeyUsage = 'serverAuth, clientAuth'

    [ alt_names ]
    DNS.1 = vertica-db-vertica-connections.*vertica-namespace*.svc.cluster.local
    DNS.2 = vertica-db-vertica-connections.*vertica-namespace*.svc
    ```

4. Create Certificate signing request file - httpvertica.csr and intervertica.csr
    ```
    openssl req -new -key httpvertica.key -out httpvertica.csr -config httpcsr.conf
    openssl req -new -key intervertica.key -out intervertica.csr -config intercsr.conf
    ```

5. Create certificate configuration file - httpcert.conf
Please note **\*vertica-namespace\*** value that needs to be replaced to actual namespace value defined in your variable group.
    ```
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = verticadb-operator-webhook-service.*vertica-namespace*.svc.cluster.local
    DNS.2 = verticadb-operator-webhook-service.*vertica-namespace*.svc
    ```

6. Create certificate configuration file - intercert.conf
Please note **\*vertica-namespace\*** value that needs to be replaced to actual namespace value defined in your variable group.
Value **\*environment-name\*** needs to be replaced to your environment name (for example - `kfr01`).
    ```
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names
    extendedKeyUsage = 'serverAuth, clientAuth'

    [alt_names]
    DNS.1 = vertica-db-vertica-connections.*vertica-namespace*.svc.cluster.local
    DNS.2 = vertica-db-vertica-connections.*vertica-namespace*.svc
    ```


7. Generate self signed certificate - httpvertica.crt and intervertica.crt
    ```
    openssl x509 -req -in httpvertica.csr -CA CA/rootCA.crt -CAkey CA/rootCA.key -CAcreateserial -out httpvertica.crt -days 1825 -sha256 -extfile httpcert.conf
    openssl x509 -req -in intervertica.csr -CA CA/rootCA.crt -CAkey CA/rootCA.key -CAcreateserial -out intervertica.crt -days 1825 -sha256 -extfile intercert.conf
    ```

8. Get base64 values for key and crt files:
    ```
    cat intervertica.key | base64 -w 0
    cat intervertica.crt | base64 -w 0
    cat CA/rootCA.key | base64 -w 0
    cat CA/rootCA.crt | base64 -w 0
    cat httpvertica.key | base64 -w 0
    cat httpvertica.crt | base64 -w 0
    ```

Base64 values must be saved into Master KV under secrets names:
* verticatlskey
* verticatlscrt
* verticatlscakey
* verticatlscacrt
* verticatlswebhookkey
* verticatlswebhookcrt
