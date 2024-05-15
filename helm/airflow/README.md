# Airflow umbrella chart

This Helm chart is umbrella chart which is using [Airflow community chart](https://github.com/airflow-helm/charts) as a base chart for Airflow deployment and creates Calico and Open Service Mesh rules for inbound and outbound connections inside and outside Kubernetes cluster.

# Calico and Open Service Mesh rules

Chart has templates both for Calico and Open Service Mesh rules. All template files that starts with `calico-` contains Calico TCP/IP rules with namespace, vnets and/or ports that allowed. All template files that starts with `osm-` contains Open Service Mesh HTTP/S and TCP/UDP rules namespace, vnets and/or ports that allowed.

## Calico rules

First of all, we have `calico-deny-all.yml` template that contains `airflow-deny-all` set of rules. 

It has rule that blocks all inbound and outbound TCP traffic to/from all resources in `airflow` namespace. Also, it has rule to log all packets that were blocked to `syslog` of Kubernetes Node. 

This set of rules has `100` order which is considered as the lowest priority rule and it is executed only when traffic doesn't meet any other rule.

### General set of rules 

Second set of rules is defined in `calico-airflow-general-allow.yml` template. It contains only allowed outbound rules (inbound rules might be added later if needed). Set of rules applies to resources in `airflow` namespace which has `app: airflow` label in place. 

It has rule that allows outbound TCP traffic on port `443` (which is SSL/TLS default port) to Kubernetes API, Private Endpoints subnet and Databricks Web application public endpoints. 

Also, it has rule that allows TCP connections to `vertica` namespace on Vertica listening port (by default `5433`). 

Another rule allows all TCP connections to `kube-system` namespace pods. It is required to ensure proper work of Kubernetes cluster and pods inside `airflow` namespace. Additionally, port `53` of UDP traffic is allowed to `kube-system` namespace to ensure proper work of DNS service.

Finally, rule that allow TCP outbound connections inside `airflow` namespace to the pods with `app: airflow` label in place. This rule is required to ensure that Open Service Mesh Envoy containers can connect to the each other in the Mesh included namespace. Unfortunately, it is impossible to specify ports for it due to broad range of port in use.

This set of rules has `11` order which is applied before `airflow-deny-all` rule, but after next set of rules defined.

### Airflow Web Application set of rules

Third set of rules is defined in `calico-airflow-web-allow.yml` template. It contains only allowed inbound rules (outbound rules might be added later if needed). Set of rules applies to resources in `airflow` namespace which has `app: airflow` and `component: web` labels in place. 

It has rules that allows TCP connections from other resources in `airflow` namespace with `app: airflow` labels and connections from Ingress Controller's pods with label `controller: ingress-nginx` in `ingress-controller` namespace. The only port allowed is Web application listening port (by default `8080`).

This set of rules has `10` order which is applied before any rules.

### Airflow PGBouncer set of rules

Last Calico set of rules is defined in `calico-airflow-pgbouncer-allow.yml` template. It contains allowed inbound and outbound rules. Set of rules applies to resources in `airflow` namespace which has `app: airflow` and `component: pgbouncer` labels in place. 

It has rule that allows inbound TCP connections from other resources in `airflow` namespace with `app: airflow` labels on `pgbouncer` listening port (by default `6432`).

Second rule allows outbound TCP connections to `postgresql` subnet. Only postgresql port (by default `5432`) is allowed to be utilized for connections to that subnet.

This set of rules has `10` order which is applied before any rules.

## Open Service Mesh rules

Open Service Mesh denies all connections outside Mesh network by default. So, this block will contain only allow rules.

### Ingress Controller as Mesh entry point

First of all, we had to specify Service Mesh entrypoint for inbound connections outside Mesh. Object `IngressBackend` specify Service Mesh object for Ingress Controller, which has information about Ingress Controller Load Balancer Service and Service Account in `sources` block, and Airflow Web service, ports and protocol type in the `backend` block as it is the only service which needs to be available via Ingress Controller. This object is specified in the `osm-ingress-backend.yml` file.

### Airflow Web application traffic targets

Next, we have to specify inbound ports and targets for resources that should accept connections from workloads inside the Mesh. This can be done by specifying `TCPRoute` objects with ports defined and with `TrafficTarget` object which has actual allow rules. For Airflow Web, we have `osm-web-traffictarget.yml` file which specify those. Object `TCPRoute` contains external port of Airflow Web (by default `8080`) and `TrafficTarget` object contains link to previously specified `TCPRoute` rule, `airflow` service account in `sources` and `destination` object to allow all Airflow resources connect to Airflow Web API. This is required to ensure that all resources can communicate with Airflow Web service and work properly.

### Airflow PGBouncer application traffic targets

Same as previous topic, we need to specify  inbound ports and targets for resources that should accept connections from workloads inside the Mesh for PGBouncer service. `TCPRoute` object contains inbound port of PGBouncer (by default `6432`) and `TrafficTarget` object with the similar rules as specified in previous topic. We are allowing connections from/to all Airflow worloads in the `airflow` namespace on port `6432`. File `osm-pgbouncer-traffictarget.yml` contains those objects and rules.

If you think that we are specifying too broad allow rules, please note that Calico has more granular rules and it covers all cases that Open Service Mesh doesn't cover. Basically, Calico won't allow to connect to port `6432` to others pods except PGBouncer pod. Unfortunately, due to design of Open Service Mesh which can work only with Service Accounts and design of Airflow Community Chart which creates Service Accounts, we have to allow such connections in a such broad way. Airflow Community chart can create only one `ServiceAccount` object with name `airflow`. It doesn't have options for separate Service Accounts per workload/service. If Airflow Community Chart supported more granular Service Account creation, we would be able to create more precise and strict rules.

### Airflow Egress rules

Finally, Egress rules needs to be specified which will list allow outbound connection from Mesh. File `osm-egress-rules.yml` has all egress rules for whole Airflow namespace resources in the Mesh. Egress rules are specified using `Egress` object with definitions of ports, protocols, IP/CIDR block addresses and hosts. We have 3 rules in general (might be changed in the future) - `hosts-https-allow`, `postgres-tcp-allow` and `vertica-tcp-allow`.

First rule - `hosts-https-allow` contains all hosts that can be accessed by Airflow workload resources via port `443` and `HTTPS` protocol. This can be customized via Umbrella chart variables, but, by default, it contains these three hosts that must be specified:

- `kubernetes` - Kubernetes cluster API external host. This is required to ensure Kubernetes can properly work with Readiness and Liveness probes. Without it, Kubernetes probes won't work at all.
- `databricks` - Databricks Web API host to ensure Airflow proper work with Databricks service.
- `microsoft_login` - By default: `login.microsoftonline.com`. Required for Service Connections to properly authenticate with Azure resources and access required data. (For example - Workers need to access DAGs that are stored in Storage Account secured under authorization system)

In addition to the hosts above, we have some defined on the pipelines level:

- `sa_airflow_blob` - Private Endpoint Hostname of Airflow Storage Account - Blob endpoint
- `sa_dl_blob` - Private Endpoint Hostname of Data Lake Storage Account - Blob endpoint
- `sa_temp_blob` - Private Endpoint Hostname of Temporary Storage Account - Blob endpoint
- `sa_dl_dfs` - Private Endpoint Hostname of Data Lake Storage Account - DFS endpoint
- `sa_temp_dfs` - Private Endpoint Hostname of Temporary Storage Account - DFS endpoint
- `sa_dl_file` - Private Endpoint Hostname of Data Lake Storage Account - File endpoint

Also, we are specifying public endpoints for each of Storage Account endpoint under `blob.core.windows.net`, `dfs.core.windows.net` and `file.core.windows.net`. This is required to ensure proper work of DAGs and Azure VNet routing to the Private Endpoint. 

Please note that Open Service Mesh allows connections to the public endpoints of Storage Accounts, Calico won't allow such connections and connections to the private endpoints will be allow only. Azure VNet resources resolves public FQDNs with the private IP addresses for each resource that has Private Endpoint in the VNet attached.

Second rule is `postgres-tcp-allow` which allows connections to the PostgreSQL subnet on DB port (by default `5432`). Protocol is the `tcp-server-first` type which is recommended protocol of Open Service Mesh for all Database connections. If you would like to learn more about protocols for Database, please [read this page](https://release-v1-2.docs.openservicemesh.io/docs/demos/egress_policy/).

Final rule is `vertica-tcp-allow` which allows connections to the Vertica pods to specific port (by default `5433`) inside Kubernetes cluster. Due to deployment inside cluster, we are allowing connections to the Nodes subnet (where all Load Balancers are deployed), services (due to initial connection to the Vertica pods via Service) and to all Calico CNI network (where pods are actually deployed). Vertica is deployed outside the Mesh and that's why we have to specify `Egress` object instead of `TrafficTarget`. Same as with public FQDNs for Storage accounts, Calico rules are specifying access more precisely in this case and allows connections only to the `vertica` namespace.

# Update procedure for Airflow chart

We are using [Airflow community chart](https://github.com/airflow-helm/charts) as a base chart for Airflow deployment. Unfortunately, this chart, apart of huge advantages, has issues that needs to be fixed on our side to ensure that it is working on our environments. This README file describes what changes have been done and what changes needs to be done during Chart version update.

## Chart update

This README file doesn't cover standard Chart update steps and defines only additional steps that needs to be done. Please follow steps below to ensure all required changes to be in place.

## Update Chart.yaml and values.yaml of Community Chart

First of all, untar `airflow-<version>.tgz` file in `charts` folder and open untar'ed folder. Then modify version of Chart in file `Chart.yaml`. Please add postfix `+intrum-<rev#>` to version to ensure that it is not clear Community Chart version. In the result it should look like this:

```
Chart.yaml
---
...
version: 8.8.0+intrum-1
```

Also, please modify `values.yaml` file and introduce new variable for Chart which will be flag for Chart and initialization containers behavior. 

```
values.yaml
---
...
airflow:
  init:
    useKubectl: false
  preStop:
    custom: false
    command: trap 'ncat 127.0.0.1 15000 --sh-exec "echo -ne \"POST /quitquitquit HTTP/1.1\nHost: 127.0.0.1:15000\n\n\""' EXIT
...
```

This variable tells Chart to use `kubectl` commands for initialization containers in the pods of Chart instead of Python commands and direct connections to the pods. 

By default it should be `false` to ensure that we are using same mechanisms as it was intended by Community Chart developers.

## Services modifications

To ensure proper Open Service Mesh (OSM) traffic utilization, all TCP services must be modified. OSM requires services to define `appProtocol` field explicitly for TCP services. 

This field tells OSM that traffic needs to be maintained as TCP traffic, not HTTP. If this field is not specified, OSM will maintain traffic as HTTP/S and apply to it OSI L7 rules defined.

You need to modify these two files*:
 - templates/worker/worker-service.yaml
 - templates/pgbouncer/pgbouncer-service.yaml

```
* Note that list of files represents files for Chart version 8.8.0. File names and number of files might differ in different Chart version. Please double check all `*-service.yaml` files in Chart and ensure that all TCP traffic services has `appProtocol` field specified.
```

Service files should look like this in the end:
```
pgbouncer-service.yaml
---
apiVersion: v1
kind: Service
...
spec:
  type: ClusterIP
  ports:
    - name: pgbouncer
      protocol: TCP
      appProtocol: TCP
      port: 6432
  ...
---

worker-service.yaml
---
apiVersion: v1
kind: Service
...
spec:
  type: ClusterIP
  ports:
    - name: worker
      protocol: TCP
      appProtocol: TCP
      port: 8793
  ...
```

## Airflow role modification

Additional permissions for Deployments and Jobs reading needs to be granted to `airflow` ServiceAccount. This can be accomplished by modifying Airflow role that is generated in scope of Chart as well.

File `templates/rbac/airflow-role.yaml` needs to be modified. Block below should be added under `.rules` object of `airflow` role.

```
rules:
...
{{- if .Values.airflow.init.useKubectl }}
- apiGroups:
  - "apps"
  resources:
  - deployments
  verbs:
  - "get"
  - "list"
  - "watch"
- apiGroups:
  - "batch"
  resources:
  - jobs
  verbs:
  - "get"
  - "list"
  - "watch"
{{- end }}
```

This will allow Airflow pods to call Kubernetes API and get statuses of Deployments and Jobs deployed in the namespace.

## Check Database and Wait for Migration templates modification

Last and most important modification that needs to be done - add `kubectl` commands to `check-db` and `wait-for-migrations` initialization containers templates. Templates are located in file `templates/_helpers/pods.tpl`.

### Check Database

Array `args` should be replaced by block below under `airflow.init_container.check_db` template.

```
...
args:
  - "bash"
  - "-c"
  {{- if and .Values.airflow.init.useKubectl (include "airflow.pgbouncer.should_use" .) }}
  - "kubectl rollout status deployment/{{ include "airflow.fullname" . }}-pgbouncer -n {{ .Release.Namespace }} --timeout 60s"
  {{- else }}
  - ... <- Standard logic from original Chart
  {{- end }}
...
```

As you can see, we add logic that if `airflow.init.useKubectl` equals `true` and we are using PGBouncer, we need to run `kubectl rollout` command to check with Kubernetes API status of PGBouncer deployment. Otherwise, standard Chart logic should be used.

In the end, the whole `airflow.init_container.check_db` template should look like this:

```
{{- define "airflow.init_container.check_db" }}
- name: check-db
  {{- include "airflow.image" . | indent 2 }}
  envFrom:
    {{- include "airflow.envFrom" . | indent 4 }}
  env:
    {{- include "airflow.env" . | indent 4 }}
  command:
    {{- include "airflow.command" . | indent 4 }}
  args:
    - "bash"
    - "-c"
    {{- if and .Values.airflow.init.useKubectl (include "airflow.pgbouncer.should_use" .) }}
    - "kubectl rollout status deployment/{{ include "airflow.fullname" . }}-pgbouncer -n {{ .Release.Namespace }} --timeout 60s"
    {{- else }}
    {{- if .Values.airflow.legacyCommands }}
    - "exec timeout 60s airflow checkdb"
    {{- else }}
    - "exec timeout 60s airflow db check"
    {{- end }}
    {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
    {{- .volumeMounts | indent 4 }}
  {{- end }}
{{- end }}
```

### Wait for Migrations

Similar modifications needs to be done in `airflow.init_container.wait_for_db_migrations` template as well. Array `args` needs to be modified:

```
args:
  {{- if .Values.airflow.legacyCommands }}
  ... <- Standard logic from original Chart
  {{- else }}
  - "bash"
  - "-c"
  {{- if and (.Values.airflow.init.useKubectl) (.Values.airflow.dbMigrations.enabled) }}
  {{- if (not .Values.airflow.dbMigrations.runAsJob) }}
  - "kubectl rollout status deployment/{{ include "airflow.fullname" . }}-db-migrations -n {{ .Release.Namespace }} --timeout 60s"
  {{- else }}
  - "kubectl wait --for=condition=complete job/{{ include "airflow.fullname" . }}-db-migrations  -n {{ .Release.Namespace }} --timeout 60s"
  {{- end }}
  {{- else }}
  - "exec airflow db check-migrations -t 60" <- Standard logic from original Chart
  {{- end }}
  {{- end }}
```

As you can see, Chart determines whether Database migrations are executed as deployments or jobs and executes `kubectl rollout` or `kubectl wait` command for checking whether deployments/jobs are finished. 

Please note that, at the moment, we don't have any migrations and if migrations will be fast enough, it should be enough with existing `kubectl rollout` command. However, if migrations will last more than 10 seconds, additional logic needs to be implemented for Migration Deployment. Python migration check logic can be executed as a part of main container execution if needed. This will bypass issue with Open Service Mesh.

In the end, the whole `airflow.init_container.wait_for_db_migrations` template should look like this:

```
{{- define "airflow.init_container.wait_for_db_migrations" }}
- name: wait-for-db-migrations
  {{- include "airflow.image" . | indent 2 }}
  envFrom:
    {{- include "airflow.envFrom" . | indent 4 }}
  env:
    {{- include "airflow.env" . | indent 4 }}
  command:
    {{- include "airflow.command" . | indent 4 }}
  args:
    {{- if .Values.airflow.legacyCommands }}
    - "python"
    - "-c"
    - |
      import logging
      import os
      import time

      import airflow
      from airflow import settings

      # modified from https://github.com/apache/airflow/blob/2.1.0/airflow/utils/db.py#L583-L592
      def _get_alembic_config():
          from alembic.config import Config

          package_dir = os.path.abspath(os.path.dirname(airflow.__file__))
          directory = os.path.join(package_dir, 'migrations')
          config = Config(os.path.join(package_dir, 'alembic.ini'))
          config.set_main_option('script_location', directory.replace('%', '%%'))
          config.set_main_option('sqlalchemy.url', settings.SQL_ALCHEMY_CONN.replace('%', '%%'))
          return config

      # copied from https://github.com/apache/airflow/blob/2.1.0/airflow/utils/db.py#L595-L622
      def check_migrations(timeout):
          """
          Function to wait for all airflow migrations to complete.
          :param timeout: Timeout for the migration in seconds
          :return: None
          """
          from alembic.runtime.migration import MigrationContext
          from alembic.script import ScriptDirectory

          config = _get_alembic_config()
          script_ = ScriptDirectory.from_config(config)
          with settings.engine.connect() as connection:
              context = MigrationContext.configure(connection)
              ticker = 0
              while True:
                  source_heads = set(script_.get_heads())
                  db_heads = set(context.get_current_heads())
                  if source_heads == db_heads:
                      break
                  if ticker >= timeout:
                      raise TimeoutError(
                          f"There are still unapplied migrations after {ticker} seconds. "
                          f"Migration Head(s) in DB: {db_heads} | Migration Head(s) in Source Code: {source_heads}"
                      )
                  ticker += 1
                  time.sleep(1)
                  logging.info('Waiting for migrations... %s second(s)', ticker)

      check_migrations(60)
    {{- else }}
    - "bash"
    - "-c"
    {{- if and (.Values.airflow.init.useKubectl) (.Values.airflow.dbMigrations.enabled) }}
    {{- if (not .Values.airflow.dbMigrations.runAsJob) }}
    - "kubectl rollout status deployment/{{ include "airflow.fullname" . }}-db-migrations -n {{ .Release.Namespace }} --timeout 60s"
    {{- else }}
    - "kubectl wait --for=condition=complete job/{{ include "airflow.fullname" . }}-db-migrations  -n {{ .Release.Namespace }} --timeout 60s"
    {{- end }}
    {{- else }}
    - "exec airflow db check-migrations -t 60"
    {{- end }}
    {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
    {{- .volumeMounts | indent 4 }}
  {{- end }}
{{- end }}
```

### Pre Stop behavior for Jobs and Deployments

Due to Envoy proxy sidecar container which supposed to run indefinitely, there are issues with Jobs (any kind) and Deployments (without Liveness probes), which can be run for limited time. Envoy proxy might block these pods restarts due to that. To solve this issue, we introduced [envoy-sidecar-helper container](https://github.com/maksim-paskal/envoy-sidecar-helper) to monitor main container activity. Airflow chart doesn't support it out of the box properly and due to that we need to do modifications below to ensure it.

First of all need to add this template to `templates/_helpers/pods.tpl`:

```
{{- define "airflow.container.envoy_helper" }}
- name: envoy-helper
  image: {{ .Values.envoyHelper.image.repository }}:{{ .Values.envoyHelper.image.tag }}
  imagePullPolicy: {{ .Values.envoyHelper.image.pullPolicy }}
  {{- if .Values.envoyHelper.resources }}
  resources:
    {{- toYaml .Values.envoyHelper.resources | nindent 4 }}
  {{- end }}
  args:
    - -container={{ .container }}
    - -log.level={{ .Values.envoyHelper.logLevel }}
    - -envoy.ready.check={{ .Values.envoyHelper.envoy.ready.check | toString | lower }}
    - -envoy.ready.port={{ .Values.envoyHelper.envoy.ready.port }}
    - -envoy.port={{ .Values.envoyHelper.envoy.port }}
    - -envoy.endpoint.quit={{ .Values.envoyHelper.envoy.endpoint.quit }}
    - -envoy.endpoint.ready={{ .Values.envoyHelper.envoy.endpoint.ready }}
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
{{- end }}
```

Then need to modify all templates of all jobs, deployments without liveness probes and `files/pod_template.kubernetes-helm-yaml` to use that template. You can do this by adding lines below.

In the begining of the template file:
```
{{- $container := toString "base" }}
```

Replace main container name to use that variable:
```
...
spec.
  containers:
    - name: {{ $container }}
...
```

And finally, add this block under `.spec.templates.spec.containers` (in case of `files/pod_template.kubernetes-helm-yaml` - `.spec.containers`) object:
```
...
spec:
  containers:
  {{- if .Values.envoyHelper.enabled }}
  {{- include "airflow.container.envoy_helper" (dict "Values" .Values "container" $container) | indent 8 }}
  {{- end }}
...
```

Please note that indent number should be `8` for all templates except `files/pod_template.kubernetes-helm-yaml`. For `files/pod_template.kubernetes-helm-yaml` it should be `4`.
## Final modifications

Finally, you need to package back and push to ACR whole Chart by running command:

```
helm package ./helm/airflow/charts/airflow/
helm push airflow-<version>+intrum-<rev#>.tgz oci://acrdevdaweucentralmanual.azurecr.io/charts
```

After that, please remove all untar'ed files, `Chart.lock` and `charts/` folder of our Umbrella Chart for Airflow Community Chart. 
Update version of Community Chart in `Chart.yaml` file. Part of it should look like this in the end:

```
Chart.yaml
---
...
dependencies:
  - name: airflow
    version: "8.8.0+intrum-1"  
    repository: "oci://acrdevdaweucentralmanual.azurecr.io/charts"
```

Run these commands to obtain new Chart from ACR:

```
az login
az acr login -n acrdevdaweucentralmanual
helm dependency build helm/airflow/
```

These commands will generate new `Chart.lock` file, download back modified Community Chart and save it under `charts/` folder.

# Generate Ingress certificates

We have enabled HTTPS connections to the Airflow Web server. HTTPS connections require SSL certificate to be generated. You can request it for yourself via Fujitsu service desk or generate self-signed certificate. Please follow steps below to generate your own certificate for Airflow Web server.

1. This step can be skipped if you wish to re-use already existing CA certificate (e.g. Vertica CA certificate). However, if you don't have Vertica CA or you wish to use separate CA certificate for Ingress Airflow Web connections, please follow steps below. Generate CA certificates and keys:
    ```
    mkdir CA
    openssl req -x509 -sha256 -days 1825 -nodes -newkey rsa:2048 -subj "/CN=ca.vertica.svc/C=LV/L=Riga" -keyout CA/rootCA.key -out CA/rootCA.crt
    ```

2. Generate Ingress Airflow key for HTTPS connection
    ```
    openssl genrsa -out ingress.key 2048
    ```

3. Create Certificate signing request configuration file - ingresscsr.conf.
Please note **\*environment-name\*** value that needs to be replaced to actual namespace value defined in your variable group.
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
    CN = *environment-name*.da.intrum.cloud

    [ req_ext ]
    subjectAltName = @alt_names

    [ alt_names ]
    DNS.1 = airflow.*environment-name*.da.intrum.cloud
    DNS.2 = vertica.*environment-name*.da.intrum.cloud
    DNS.3 = localhost
    ```

4. Create Certificate signing request file - ingress.csr
    ```
    openssl req -new -key ingress.key -out ingress.csr -config ingresscsr.conf
    ```

5. Create certificate configuration file - ingresscert.conf
Please note **\*environment-name\*** value that needs to be replaced to actual namespace value defined in your variable group.
    ```
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = airflow.*environment-name*.da.intrum.cloud
    DNS.2 = vertica.*environment-name*.da.intrum.cloud
    DNS.3 = localhost
    ```

6. Generate self signed certificate - ingress.crt
    ```
    openssl x509 -req -in ingress.csr -CA CA/rootCA.crt -CAkey CA/rootCA.key -CAcreateserial -out ingress.crt -days 1825 -sha256 -extfile ingresscert.conf
    ```

8. Get base64 values for key and crt files:
    ```
    cat ingress.key | base64 -w 0
    cat ingress.crt | base64 -w 0
    ```

Base64 values must be saved into Master KV under secrets names:
* clienttlskey
* clienttlscrt
