# KeyCloak HA Cluster with Infinispan

This repository contains the necessary files to deploy a KeyCloak HA Cluster with Infinispan as a cache provider.  
There are 3 ways to deploy this cluster:

- Using Docker Compose
- Using Docker Swarm
- Using Kubernetes

---

## Table of Contents

- [KeyCloak HA Cluster with Infinispan](#keycloak-ha-cluster-with-infinispan)
  - [Table of Contents](#table-of-contents)
  - [Docker Compose](#docker-compose)
    - [Prerequisites](#prerequisites)
    - [Running clusters](#running-clusters)
    - [Stopping clusters](#stopping-clusters)
  - [Docker Swarm](#docker-swarm)

---

## Docker Compose

### Prerequisites

First of all, you have to build the KeyCloak image:

```bash
docker compose build
```

There are 3 reasons for this:

1. Default KeyCloak image is not meant to be used in production.  
   [Check the official documentation](https://www.keycloak.org/server/containers) for more information.
2. Since we are using Infinispan as a cache provider,  
   we need to pass the `cache-ispn-remote.xml` file to the `build` command.  
   This file is used to configure the Infinispan cache provider.
3. To perform **health checks** on the KeyCloak instances,  
   we need to install the `curl` package in the image.

> If you want to **import existing realms**, you can put the JSON files in the `config/keycloak/realms` directory.  
> KeyCloak will import them automatically when the container starts.

### Running clusters

Copy the `.example.env` file to `.env` and change the values as needed.  
Then, run the following command:

```bash
docker-compose up -d
```

Wait for the containers to start.
You can check the status of the containers by running:

```bash
docker-compose ps
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
docker-compose down
```

If you want to remove the volumes as well, run:

```bash
docker-compose down -v
```

---

## Docker Swarm