*This project has been created as part of the 42 curriculum by mjusta.*

# Inception

Inception is a system administration project from the 42 curriculum. The goal is to build a small containerized web infrastructure inside a virtual machine using Docker Compose. The project uses custom Dockerfiles for each service and focuses on service isolation, networking, persistent storage, TLS, secrets, and container orchestration. 

---

## Table of content
1. [Description](#1-description)
2. [Architecture](#2-architecture)
3. [Directory Structure](#3-directory-structure)
4. [Design Choices](#4-design-choices)
    - [4.1 Virtual Machines vs Docker](#41-virtual-machines-vs-docker)
    - [4.2 Secrets vs Environment Variables](#42-secrets-vs-environment-variables)
    - [4.3 Docker Network vs Host Network](#43-docker-network-vs-host-network)
    - [4.4 Docker Volumes vs Bind Mounts](#44-docker-volumes-vs-bind-mounts)
5. [Instructions](#5-instructions)
    - [5.1 Prerequisites](#51-prerequisites)
    - [5.2 Setup](#52-setup)
    - [5.3 Build and Run](#53-build-and-run)
    - [5.4 Stop and Clean](#54-stop--clean)
    - [5.5 Access](#55-access)
    - [5.6 Troubleshooting](#56-troubleshooting)
6. [Services](#6-services)
    - [6.1 Mandatory Services](#61-mandatory-services)
    - [6.2 Bonus Services](#62-bonus-services)
    - [6.3 Service Interaction](#63-service-interaction)
7. [Data Persistence](#7-data-persistence)
8. [Security Notes](#8-security-notes)
9. [Resources](#9-resources)
    - [9.1 Official documentation](#91-official-documentation)
    - [9.2 How AI was used](#92-how-ai-was-used)

---

## 1. Description

Inception is a Docker-based infrastructure project. It requires building a small web stack made of several services, each running in its own container and each built from its own Dockerfile. The mandatory stack contains NGINX, WordPress with php-fpm, and MariaDB.

The mandatory infrastructure is composed of:

- an NGINX container that exposes HTTPS on port `443`,
- a WordPress container running `php-fpm`, without NGINX,
- a MariaDB container, without NGINX,
- a Docker network for communication between containers,
- one named volume for WordPress website files,
- one named volume for MariaDB database files.

The project also includes bonus services:

- Redis cache for WordPress,
- FTP server pointing to the WordPress website volume,
- Adminer for database administration,
- a static website served from its own container,
- Glances as an additional monitoring service of choice.

All services are orchestrated with Docker Compose and managed through the root `Makefile`.

---

## 2. Architecture

The infrastructure is built as a group of isolated containers connected through a dedicated Docker network.

NGINX is the mandatory public entry point. It listens on port `443` and serves the WordPress site through HTTPS using TLSv1.2 or TLSv1.3. NGINX does not process PHP directly. Instead, it forwards PHP requests to the WordPress container.

The WordPress container contains the WordPress application files and runs `php-fpm`. It communicates with MariaDB through the internal Docker network and stores website files in a persistent named volume.

The MariaDB container stores the WordPress database. It is not exposed directly to the host and is reachable only by internal containers on the Docker network.

Redis is used as an object cache for WordPress. WordPress reaches it through the internal Docker network using the Redis service name.

Adminer is exposed on port `8080` as a browser-based database administration tool. It connects to MariaDB through the Docker network.

The FTP server exposes port `21` and passive ports for file transfer. It mounts the same WordPress website volume so an administrator can access the WordPress files.

The static website is served by its own container and is exposed on port `8081`.

Glances is exposed on port `61208` and provides a lightweight web interface for monitoring system resource usage.

The mandatory infrastructure keeps NGINX as the only entry point on port `443`. Bonus services may expose additional ports when needed.

---

## 3. Directory Structure

The project is organized to separate orchestration files, service definitions, configuration, and helper scripts in a clear and maintainable way.

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── redis/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            ├── adminer/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            ├── static_site/
            │   ├── Dockerfile
            │   ├── conf/
            │   ├── html/
            │   └── tools/
            ├── ftp/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            └── glances/
                ├── Dockerfile
                └── tools/
```

### Root files

---

#### `Makefile`

The main entry point for managing the project. It runs Docker Compose commands through simple targets such as `make`, `make down`, `make clean`, and `make fclean`.

#### `README.md`

General documentation explaining the project purpose, architecture, design choices, setup, services, security notes, and resources.

#### `USER_DOC.md`

User-oriented documentation explaining how to start, stop, access, and verify the stack.

#### `DEV_DOC.md`

Developer-oriented documentation explaining setup, configuration, secrets, Docker Compose usage, data persistence, and maintenance commands.

---

### `srcs/`

This folder contains the infrastructure files required to launch the project.

#### `srcs/.env`

Stores non-secret environment variables used by Docker Compose and the containers. Examples include the domain name, database name, database user, WordPress users, and host data path.

#### `srcs/docker-compose.yml`

Defines services, builds, images, networks, volumes, ports, restart policies, dependencies, environment variables, and secrets.

### `srcs/requirements/`

This folder contains one subdirectory per service. Each service is built from its own Dockerfile.

### `srcs/requirements/bonus/`

This folder contains the optional bonus services. Each bonus service also has its own Dockerfile and runs in its own container.

### `secrets/`

This folder stores local secret files such as passwords. These files must not be committed to the repository.

---

## 4. Design Choices

### 4.1 Virtual Machines vs Docker

A virtual machine emulates a full operating system with its own kernel. It is heavier because it needs more storage, memory, and startup time.

Docker uses containers. Containers isolate applications while sharing the host kernel, which makes them lighter and faster to start than virtual machines.

In this project, the whole infrastructure is developed inside a virtual machine because the subject requires it. Inside that VM, Docker is used to split the infrastructure into separate containers. This gives both a controlled host environment and service-level isolation.

---

### 4.2 Secrets vs Environment Variables

Environment variables are useful for non-sensitive configuration values such as domain names, database names, usernames, and service options. This project uses a `.env` file for that kind of configuration.

Secrets are better for sensitive values such as passwords. Passwords should not be written directly inside Dockerfiles, scripts, or committed configuration files. In this project, passwords are stored as local secret files and mounted into containers as Docker secrets.

This separation keeps configuration convenient while reducing the risk of leaking credentials.

---

### 4.3 Docker Network vs Host Network

A Docker network allows containers to communicate with each other using service names such as `mariadb`, `wordpress`, `redis`, or `adminer`. This keeps internal communication isolated from the host network.

Host networking would make containers share the host network stack directly. That reduces isolation and makes the setup less portable.

This project uses a dedicated Docker bridge network because it is cleaner, safer, and required by the subject. Host networking, `--link`, and `links:` are not used.

---

### 4.4 Docker Volumes vs Bind Mounts

Docker volumes are designed for persistent container data. They allow data to survive when containers are stopped, removed, or rebuilt.

Bind mounts map a host directory directly into a container. They can be useful during development, but they create a stronger dependency on the host filesystem.

For the mandatory WordPress and MariaDB persistent data, this project uses Docker named volumes. These volumes are configured to store data under `/home/mjusta/data` on the host machine. This follows the subject requirement while keeping the data separate from the container lifecycle.

---

## 5. Instructions

### 5.1 Prerequisites

Before running the project, the following requirements must be met:

- A virtual machine must be set up, since the project has to be completed inside a VM.
- Docker and Docker Compose must be installed on the machine.
- A Makefile must be present at the root of the repository.
- All configuration files required by the project must be placed inside the `srcs/` directory.
- The local domain name must be configured so that `<login>.42.fr` points to the local IP address of the virtual machine.

---

### 5.2 Setup

Before launching the infrastructure, the environment must be configured:

1. Create the required project structure and service folders.
2. Create the `.env` file inside `srcs/` and define the environment variables needed by the services.
3. Store sensitive data such as passwords securely outside the repository or through secrets/local files.
4. Make sure the host directories for persistent data are available under `/home/<login>/data`.
5. Update the host configuration if necessary so that `<login>.42.fr` resolves correctly.

---

### 5.3 Build and Run

The whole infrastructure is managed through the `Makefile`, which must build and launch the services using Docker Compose.

Typical workflow:

```bash
make
```

This command should:

- build the custom Docker images,
- create and start the containers,
- create the network,
- create and attach the named volumes.

---

### 5.4 Stop / Clean

#### Stop the Project

To stop the running containers without removing data:

```bash
make down
``` 

#### Clean the Project

Remove containers and unused project resources according to the Makefile implementation:

```bash
make clean
```

Fully reset the project, including persistent volumes/data if your Makefile supports it:

```bash
make fclean
```

Be careful with full cleanup commands because they may delete WordPress files and database data.

---

### 5.5 Access

Mandatory service:

```text
https://mjusta.42.fr
https://mjusta.42.fr/wp-admin
```

Bonus services:

```text
Adminer:       http://localhost:8080
Static site:   http://localhost:8081
Glances:       http://localhost:61208
FTP:           ftp://localhost:21
Redis:         internal only, no public port
```

If the project runs inside a VM and the browser is on the host machine, replace `localhost` with the VM IP for bonus services.

---

### 5.6 Troubleshooting

Check containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Check logs:

```bash
docker compose -f srcs/docker-compose.yml logs <service>
```

Rebuild one service:

```bash
docker compose -f srcs/docker-compose.yml build <service>
```

Restart the stack:

```bash
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d
```

Common things to verify:

- `mjusta.42.fr` points to the correct IP address.
- NGINX exposes port `443`.
- MariaDB and WordPress are not directly exposed to the host.
- Redis has no public port.
- The `.env` file exists inside `srcs/`.
- Secret files exist locally and are not committed.
- `/home/mjusta/data/mariadb` and `/home/mjusta/data/wordpress` exist.
- Containers are not kept alive with hacks such as `tail -f`, `sleep infinity`, or `while true`.

---

## 6. Services

### 6.1 Mandatory Services

#### NGINX

NGINX is the mandatory public entry point. It listens on port `443`, handles HTTPS, and forwards PHP requests to WordPress through php-fpm.

Main responsibilities:

- expose the website through HTTPS,
- use TLSv1.2 or TLSv1.3,
- serve static WordPress files when appropriate,
- forward PHP requests to the WordPress container,
- keep WordPress and MariaDB hidden from direct public access.

#### WordPress + php-fpm

The WordPress container runs the application layer. It contains WordPress files and uses `php-fpm` to process PHP requests.

Main responsibilities:

- install and configure WordPress,
- create the required WordPress users,
- process PHP requests,
- connect to MariaDB,
- use Redis as an object cache when the bonus is enabled,
- store website files in the `wordpress_data` volume.

#### MariaDB

MariaDB stores the WordPress database.

Main responsibilities:

- create the WordPress database,
- create the database user,
- store application data persistently,
- remain reachable only through the internal Docker network.


### 6.2 Bonus Services

#### Redis

Redis is used as an object cache for WordPress. It improves caching by reducing repeated database queries. It is internal only and does not expose a public port.

#### Adminer

Adminer is a lightweight database administration interface. It is exposed on port `8080` and connects to MariaDB through the internal Docker network.

#### Static Website

The static website is served from its own container and does not use PHP. It is exposed on port `8081`.

#### FTP

The FTP server points to the WordPress website volume. It allows an administrator to access the WordPress files through FTP. It uses a Docker secret for the FTP password.

#### Glances

Glances is the custom bonus service of choice. It provides a lightweight web interface for monitoring resource usage and is exposed on port `61208`.

### 6.3 Service Interaction

The mandatory request flow is:

1. A client opens `https://mjusta.42.fr`.
2. NGINX receives the HTTPS request on port `443`.
3. NGINX forwards PHP requests to WordPress on the internal network.
4. WordPress processes PHP through php-fpm.
5. WordPress communicates with MariaDB through the internal Docker network.
6. WordPress optionally uses Redis for object cache.
7. WordPress files and database files remain stored in persistent named volumes.

Bonus service access:

- Adminer connects to MariaDB using the hostname `mariadb`.
- FTP mounts the same WordPress volume used by WordPress.
- The static site runs independently in its own container.
- Glances provides monitoring through its own exposed web interface.

---

## 7. Data Persistence

Data persistence is required because important application data must survive container restarts, rebuilds, and recreation.

The project uses two mandatory named volumes:

- `mariadb_data` for the MariaDB database files,
- `wordpress_data` for the WordPress website files.

The volumes are configured to store their data under:

```text
/home/mjusta/data/mariadb
/home/mjusta/data/wordpress
```

This makes the data available on the host machine while still managing it through Docker named volumes.

The FTP bonus service mounts the same `wordpress_data` volume so the WordPress website files can be accessed through FTP.

Containers are considered replaceable. Persistent data should live in volumes, not inside container filesystems.

---

## 8. Security Notes

The mandatory infrastructure limits public exposure by using NGINX as the only public entry point on port `443`.

WordPress, MariaDB, and Redis are not exposed directly to the host. They communicate through the internal Docker network.

Passwords are not stored in Dockerfiles. Sensitive values are stored in local secret files and passed to containers as Docker secrets.

The `.env` file is used for non-secret configuration. If it contains only non-sensitive values, it may be easier to review. If any confidential values are added to it, it must not be committed.

Bonus services expose extra ports because the bonus section allows additional ports when required. These services are intended for local development and administration.

Each service runs in its own container and has its own Dockerfile. Ready-made service images are not used.

No container should rely on fake long-running commands such as:

```bash
tail -f
sleep infinity
while true
```

The main service process should run in the foreground, usually through `exec` in the init script.

---

## 9. Resources

### 9.1 Official documentation
- [Docker Docs — Compose overview](https://docs.docker.com/compose/)
- [Docker Docs — Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker Docs — Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Docs — Docker build best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker Docs — Networking](https://docs.docker.com/engine/network/)
- [Docker Docs — Volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker Docs — Storage: volumes and bind mounts](https://docs.docker.com/engine/storage/)
- [Docker Docs — Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX Docs — Configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [NGINX Docs — ngx_http_ssl_module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [WordPress Developer Docs — NGINX / php-fpm setup notes](https://developer.wordpress.org/advanced-administration/server/web-server/nginx/)
- [MariaDB Docs — MariaDB in Docker and environment variables](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/mariadb-server-docker-official-image-environment-variables)
- [Redis Documentation](https://redis.io/docs/latest/)
- [Adminer Documentation](https://www.adminer.org/)
- [vsftpd Project Page](https://security.appspot.com/vsftpd.html)
- [Glances Documentation](https://glances.readthedocs.io/)

---

### 9.2 How AI was used
AI was used for:
- summarizing subject requirements,
- helping draft documentation structure,
- reviewing wording for clarity,
- comparing Docker concepts for the README,
- suggesting learning resources.

> AI was not used as a replacement for understanding the project. All generated explanations, commands, service descriptions, and design notes were reviewed, adjusted, and tested manually before being included.

