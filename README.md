# KeyCloak HA Cluster with Infinispan

This repository contains the necessary files to deploy a KeyCloak HA Cluster with Infinispan as a cache provider.  
There are 3 ways to deploy this cluster:

- **Using Docker Compose**
- **Using Docker Swarm**
- **Using Kubernetes**

---

## Table of Contents

- [Building images & Helm chart](#building-images--helm-chart)
  - [KeyCloak](#keycloak)
  - [Infinispan](#infinispan)
  - [Helm chart](#helm-chart)
- [Docker Compose](#docker-compose)
  - [Prerequisites](#prerequisites)
  - [Running clusters](#running-clusters)
  - [Stopping clusters](#stopping-clusters)
- [Kubernetes](#kubernetes)
  - [Helm chart](#helm-chart-1)
    - [Using with HashiCorp Vault](#using-with-hashicorp-vault)
  - [Accessing services](#accessing-services)
  - [Importing realms](#importing-realms)

---

## Building images & Helm chart

Since all the images and Helm chart are already built and available in the OCI registry, you can skip this step.  
Or you can build them yourself by following the instructions below.

### KeyCloak

Review the files under the `config/keycloak` directory, as well as the `keycloak.Dockerfile` file.
The attached files include the following configurations:

- `keycloak.conf`:
  allow to access the KeyCloak by any host without SSL
- `cache-ispn-remote.xml`:
  Infinispan cache provider configuration
- `realms`:
  Directory for importing realms
- `keycloak.Dockerfile`:
  - Install `curl` package for Docker health checks
  - Include the configuration files in the image
  - Enable health checks and metrics
  - Build KeyCloak app for production use ([more info](https://www.keycloak.org/server/containers))

Build the KeyCloak image:

```bash
IMAGE=oshpalov/keycloak-ispn:24.0.3 # Change the image name and tag as needed
docker build -f keycloak.Dockerfile -t $IMAGE .
```

Push the image to the registry:

```bash
docker push $IMAGE
```

### Infinispan

Review the files under the `config/infinispan` directory, as well as the `infinispan.Dockerfile` file.
The attached files include the following configurations:

- `infinispan.xml`:
  Infinispan configuration with the necessary cache stores
- `infinispan.Dockerfile`:
  - Include the configuration file in the image
  - Include additional libs for Infinispan, such as `postgresql`
  - Make a volume for the data directory

Build the Infinispan image:

```bash
IMAGE=oshpalov/infinispan-ispn:15.0.7.Final # Change the image name and tag as needed
docker build -f infinispan.Dockerfile -t $IMAGE .
```

Push the image to the registry:

```bash
docker push $IMAGE
```

### Helm chart

Review the files under the `kubernetes` directory, as well as the `values.yaml` file.

At this point, you can place the KeyCloak realms in the `realms` directory.

Build the Helm chart:

```bash
helm package keycloak-ispn
```

Push the chart to the OCI registry:

```bash
VERSION=$(grep version keycloak-ispn/Chart.yaml | awk '{print $2}')
CHART_URL=oci://registry-1.docker.io/oshpalov/keycloak-ispn # Change the registry URL as needed
helm push keycloak-ispn-$VERSION.tgz $CHART_URL
```

#### Using with HashiCorp Vault

You can pass environment variables to the KeyCloak and Infinispan containers using HashiCorp Vault.  

Example of the `values.yaml` file:

```yaml
...
podAnnotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "default"
  vault.hashicorp.com/agent-inject-secret-env: "kv/data/keycloak"
  vault.hashicorp.com/agent-inject-template-env: |
    {{- with secret "kv/data/keycloak" -}}
    {{- range $key, $value := .Data.data -}}
    export {{ $key }}="{{ $value }}"
    {{- end -}}
    {{- end -}}
...
```

Data from the `kv/data/keycloak` path in the Vault will be injected into `/vaut/secrets/env` in the container.  
When the container starts, the data will be exported as environment variables.

---

## Docker Compose

### Prerequisites

First of all, you have to build the KeyCloak image:

```bash
docker compose build keycloak
```

There are 3 reasons for this:

1. Default KeyCloak image is not meant to be used in production.  
   [Check the official documentation](https://www.keycloak.org/server/containers) for more information.
2. Since we are using Infinispan as a cache provider,  
   we need to pass the `cache-ispn-remote.xml` file to the `build` command.
3. To perform **health checks** on the KeyCloak instances,  
   we need to install the `curl` package in the image.

> **NOTE:** It's not necessary to build Infinispan image,  
> since everything is configured in the `compose.yml` file.

### Running clusters

Copy the `.example.env` file to `.env` and change the values as needed.  

> **NOTE:** If you want to **import existing realms**, you can put the JSON files in the `config/keycloak/realms` directory.  
> KeyCloak will import them automatically when the container starts.

Run the following command to start the clusters:

```bash
docker compose up -d
```

Wait for the containers to start.
You can check the status of the containers by running:

```bash
docker compose ps
```

Output should be similar to this:

```bash
NAME                       IMAGE                                          COMMAND                    SERVICE      CREATED          STATUS                    PORTS
keycloak-ha-haproxy-1      haproxy:lts-alpine                             "docker-entrypoint.s…"     haproxy      2 minutes ago    Up 2 minutes (healthy)    127.0.0.1:1936->1936/tcp, 127.0.0.1:8080->8080/tcp, 127.0.0.1:11222->11222/tcp
keycloak-ha-infinispan-1   infinispan/server:15.0.7.Final                 "sh -c '\n  echo 'use…"    infinispan   2 minutes ago    Up 2 minutes (healthy)    2157/tcp, 7800/tcp, 7900/tcp, 8080/tcp, 8443/tcp, 11221-11223/tcp, 46655/tcp, 57600/tcp
keycloak-ha-infinispan-2   infinispan/server:15.0.7.Final                 "sh -c '\n  echo 'use…"    infinispan   2 minutes ago    Up 2 minutes (healthy)    2157/tcp, 7800/tcp, 7900/tcp, 8080/tcp, 8443/tcp, 11221-11223/tcp, 46655/tcp, 57600/tcp
keycloak-ha-infinispan-3   infinispan/server:15.0.7.Final                 "sh -c '\n  echo 'use…"    infinispan   2 minutes ago    Up 2 minutes (healthy)    2157/tcp, 7800/tcp, 7900/tcp, 8080/tcp, 8443/tcp, 11221-11223/tcp, 46655/tcp, 57600/tcp
keycloak-ha-keycloak-1     keycloak:24.0.3                                "/opt/keycloak/bin/k…"     keycloak     31 seconds ago   Up 28 seconds (healthy)   8080/tcp, 8443/tcp
keycloak-ha-keycloak-2     keycloak:24.0.3                                "/opt/keycloak/bin/k…"     keycloak     31 seconds ago   Up 27 seconds (healthy)   8080/tcp, 8443/tcp
keycloak-ha-keycloak-3     keycloak:24.0.3                                "/opt/keycloak/bin/k…"     keycloak     31 seconds ago   Up 28 seconds (healthy)   8080/tcp, 8443/tcp
keycloak-ha-postgres-1     postgres:16-alpine                             "sh -c '\n  echo \"CRE…"   postgres     2 minutes ago    Up 2 minutes (healthy)    5432/tcp
```

After the containers are up, you can access the following URLs:

- KeyCloak: http://localhost:8080/
- Infinispan: http://localhost:11222/
- HAProxy: http://localhost:1936/

Use the credentials defined in the `.env` file to access services.

### Stopping clusters

To stop the clusters, run the following command:

```bash
docker compose down
```

If you want to remove the volumes as well, run:

```bash
docker compose down -v
```

---

## Docker Swarm

### Requirements

- Docker Swarm cluster with at least 3 nodes
- PostgreSQL server
- [Portainer](https://docs.portainer.io/start/install-ce/server/swarm/linux) (optional)

> Since Docker Swarm doesn't support stateful services by default,
> Postgres server is not included in the stack.  
> You can use the existing PostgreSQL server or deploy a new one.

> Portainer is required to easily deploy the stack with dynamic environment variables.  
> You can use the `docker stack deploy` command as well, but you have to pass the environment variables manually.

### Prepare DB

Create a new database and user for Infinispan:

```sql
CREATE DATABASE infinispan;
CREATE USER infinispan WITH ENCRYPTED PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE infinispan TO infinispan;
```

Create a new database and user for KeyCloak:

```sql
CREATE DATABASE keycloak;
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
```

### Deploy stack

Assuming you have Portainer installed, follow these steps:

1. Create a new stack in Portainer
2. Paste the content of the `docker-swarm/keycloak-ispn-stack.yml` file
3. Update the environment variables as shown in the `.example.stack.env` file
4. Deploy the stack

> **NOTE:** You can also use gitops to deploy the stack.

---

## Kubernetes

### Helm chart

There is a Helm chart available in the `kubernetes` directory.  
To install the chart using CLI, update the `values.yaml` file with the necessary values in the `kc.env` and `ispn.env` sections.

Then run the following command:

```bash
helm install keycloak-ispn \
     --create-namespace \
     --namespace keycloak-ispn \
     --values values.yaml \
     oci://registry-1.docker.io/oshpalov/keycloak-ispn:1.0.0
```

### Accessing services

By default, the services aren't exposed to the outside world.
You can update the `values.yaml` file to expose the services using `NodePort` or `LoadBalancer`.

Also, you can enable `Ingress` by setting the `kc.ingress.enabled` and `ispn.ingress.enabled` values to `true`.

### Importing realms

There are 3 ways to import realms, depending on the environment:

1. **Using Helm chart and CLI**  
   If you're deploying the chart using CLI, you can put the JSON files in the `realms` directory.
   Realms will be included in the chart and imported automatically.
2. **Using Helm chart with GitOps**  
   If you're deploying the chart using GitOps, you can still put the JSON files in the `realms` directory.
3. **Using KeyCloak Admin Console**  
   If you're deploying packaged Helm chart, you can import realms manually using the KeyCloak Admin Console.
