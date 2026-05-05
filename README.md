*This project has been created as part of the 42 curriculum by mjusta.*

# Inception

Inception is a system administration project from the 42 curriculum focused on building a small containerized infrastructure with Docker. The goal is to set up and connect multiple services — mainly NGINX, WordPress with php-fpm, and MariaDB — inside a virtual machine, while respecting rules about networking, persistence, security, and configuration. This project is designed to introduce practical concepts such as Docker images, containers, volumes, networks, TLS, and service orchestration. 

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
    - [5.4 Stop / Clean](#54-stop--clean)
    - [5.5 Access](#55-access)
    - [5.6 Troubleshooting](#56-troubleshooting)
6. [Services](#6-services)
    - [6.1 NGINX](#61-nginx)
    - [6.2 WordPress + php-fpm](#62-wordpress--php-fpm)
    - [6.3 MariaDB](#63-mariadb)
    - [6.4 Service Interaction](#64-service-interaction)
7. [Data Persistence](#7-data-persistence)
8. [Security Notes](#8-security-notes)
9. [Resources](#9-resources)
    - [9.1 Official documentation](#91-official-documentation)
    - [9.2 How AI was used](#92-how-ai-was-used)

---

## 1. Description
Inception is a system administration project from the 42 curriculum focused on building a small web infrastructure with Docker. The project is carried out inside a virtual machine and requires the creation and configuration of several custom Docker images instead of relying on pre-built service images.

The mandatory infrastructure is composed of three main services: an NGINX container acting as the only public entrypoint through HTTPS on port 443, a WordPress container running with php-fpm, and a MariaDB container used as the database backend. These services must communicate through a dedicated Docker network, while persistent data must be stored using Docker named volumes.

A major objective of the project is to understand how containers differ from virtual machines and how multiple isolated services can work together as one application. It also introduces important practical topics such as TLS configuration, environment variables, secrets management, persistent storage, networking, container lifecycle, and service orchestration with Docker Compose.

Beyond simply making the stack run, the project also requires making clear technical choices and understanding why those choices matter. This includes comparing Docker with virtual machines, named volumes with bind mounts, Docker bridge networking with host networking, and secrets with environment variables. In that sense, Inception is not only about deployment, but also about learning the design and security principles behind a containerized infrastructure.

---

## 2. Architecture

The project is built as a small containerized infrastructure composed of three main services: NGINX, WordPress with php-fpm, and MariaDB. Each service runs inside its own dedicated container and is built from a custom Dockerfile. The containers communicate through a dedicated Docker network, which allows internal service-to-service communication while keeping the overall setup isolated and organized.

NGINX acts as the only public entrypoint of the infrastructure. It listens on port 443 and handles HTTPS connections using TLSv1.2 or TLSv1.3. Instead of serving dynamic PHP content itself, NGINX forwards PHP requests to the WordPress container, where php-fpm processes them. This separation keeps the web server and the PHP application runtime in distinct services, following a cleaner and more modular design.

The WordPress container contains the website application files and runs php-fpm to process PHP code. It does not include NGINX, in accordance with the project requirements. WordPress connects internally to the MariaDB container, which provides the database service used to store application data such as site content, configuration, and user information.

Persistence is handled through two Docker named volumes. One volume stores the WordPress website files, and the other stores the MariaDB database files. These volumes allow important data to survive container restarts, rebuilds, or recreation. According to the project requirements, both named volumes must store their data inside `/home/<login>/data` on the host machine.

The whole infrastructure is orchestrated with Docker Compose and launched through the Makefile located at the root of the repository. Environment variables are managed through a `.env` file, while sensitive data should be kept outside the repository and handled securely. This architecture makes it possible to run a multi-service web stack in a reproducible, isolated, and maintainable way while respecting the constraints of the subject.

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
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            └── tools/
```

### Root files

---

#### `Makefile`
The main entry point for managing the project. It is used to build, start, stop, and clean the infrastructure without having to write long Docker Compose commands manually.

#### `README.md`
General project documentation. It explains the purpose of the project, its architecture, setup instructions, design choices, and learning resources.

#### `USER_DOC.md`
User-oriented documentation describing how to use the stack, access services, and verify that everything is working correctly.

#### `DEV_DOC.md`
Developer-oriented documentation describing how to configure, build, debug, and maintain the project.

---

### `src/`

---

This folder contains the infrastructure files required to launch the project.

####  `.env`
Stores environment variables used by Docker Compose and the containers. It is used for configuration values such as the domain name, database user, and other setup variables.
#### `docker-compose.yml`
Defines the services, networks, volumes, restart policies, and relationships between containers.

---

### `srcs/requirements/`

---

This folder contains one subdirectory per service. Each service is built from its own custom Dockerfile, as required by the subject.

#### `nginx/`
Contains the Dockerfile, configuration files, and helper scripts for the NGINX service. This service acts as the only public entry point and handles HTTPS traffic.

#### `wordpress/`
Contains the Dockerfile, configuration files, and helper scripts for the WordPress + php-fpm service. This service runs the application logic and processes PHP requests through php-fpm.

#### `mariadb/`
Contains the Dockerfile, configuration files, and helper scripts for the MariaDB service. This service stores the WordPress database.

---

### Service subfolders

---

Each service directory usually follows the same pattern:

#### `Dockerfile`
Builds the image for the service.

#### `.dockerignore`
Prevents unnecessary files from being copied into the build context.

#### `conf/`
Stores service configuration files, such as NGINX configuration, MariaDB settings, or php-fpm / WordPress-related configuration.

#### `tools/`
Stores helper scripts used during container setup or startup, such as initialization scripts.

---

### `secrets/`

---

This folder can be used to store sensitive local files such as passwords or credentials. It should never be committed to the repository. Even when `.env` is used for general configuration, secret values should be handled carefully and kept outside version control.

---

## 4. Design Choices

### 4.1 Virtual Machines vs Docker

A virtual machine emulates an entire operating system with its own kernel, which makes it heavier in terms of storage, memory usage, and startup time. Docker, on the other hand, uses containerization to isolate applications while sharing the host system’s kernel. This makes containers much lighter and faster to start.

In this project, the infrastructure must be built inside a virtual machine, but the services themselves run in Docker containers. This combination provides both isolation at the machine level and flexibility at the service level. The virtual machine offers a controlled environment for the whole project, while Docker makes it easier to separate NGINX, WordPress, and MariaDB into dedicated services.

Docker is therefore a better fit for this project’s internal architecture because it simplifies service orchestration, reproducibility, and deployment. At the same time, the virtual machine remains useful as the required host environment in which the full stack is developed and tested.

---

### 4.2 Secrets vs Environment Variables

Environment variables are a simple and practical way to pass configuration values to containers. They are well suited for non-sensitive settings such as domain names, database names, or usernames. In this project, the use of environment variables is mandatory, and a `.env` file is required for managing them.

However, environment variables are not the most secure choice for confidential data such as passwords or private credentials. For that reason, secrets are a better option for sensitive information because they are meant to reduce the risk of exposing confidential values directly in configuration files or source code.

For this project, general configuration is stored in `.env`, while sensitive values should be stored locally and kept outside the repository. This approach follows the project requirements while also improving security and reducing the chance of leaking credentials through Git.

---

### 4.3 Docker Network vs Host Network

A Docker network allows containers to communicate with each other in an isolated internal environment. Each service can be reached by its service name, which makes communication between NGINX, WordPress, and MariaDB easier and cleaner. This also improves separation between internal traffic and externally exposed ports.

By contrast, host networking removes that layer of isolation and makes a container share the host machine’s network stack directly. While this may seem simpler, it reduces portability and weakens the separation between services and the host system.

For Inception, using a dedicated Docker network is the better design choice because it keeps the infrastructure modular and secure. It also matches the project requirements, since host networking is forbidden and a network must be explicitly defined.

---

### 4.4 Docker Volumes vs Bind Mounts

Docker volumes are managed by Docker and are designed for persistent container data. They are especially useful when data must survive container recreation, updates, or rebuilds. In this project, volumes are the correct choice for storing the MariaDB database files and the WordPress website files.

Bind mounts directly map a host directory into a container. They are convenient during development when direct access to files on the host is needed, but they create a tighter dependency between the container and the host filesystem layout.

For this project, named volumes are required and bind mounts are not allowed for the persistent WordPress and MariaDB data. This makes sense because volumes provide cleaner persistence management and better match the goal of maintaining a stable containerized infrastructure. The subject also requires these named volumes to store their data inside `/home/<login>/data` on the host machine.

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

To stop the containers and remove unused resources:

```bash
make clean
```

If a full reset is needed, including containers, images, networks, and possibly volumes, an additional rule such as `fclean` can be used depending on the Makefile implementation.

---

### 5.5 Access

Once the project is running:

- The website should be accessible through `https://<login>.42.fr`
- NGINX must be the only public entry point and must expose port `443` only
- The WordPress administration panel should usually be accessible from the standard WordPress admin path: `https://<login>.42.fr/wp-admin`

---

### 5.6 Troubleshooting

- Make sure `<login>.42.fr` points to the correct local IP address of the virtual machine.
- Check that port `443` is the only public port exposed by NGINX.
- Verify that the `.env` file is present and correctly filled.
- Confirm that the directories under `/home/<login>/data` exist and are writable.
- Use Docker commands such as `docker ps`, `docker logs`, and `docker compose logs` to inspect container status and errors.
- If a service fails to start, rebuild the images and restart the stack after checking the configuration files.

---

## 6. Services

The infrastructure is composed of three main services, each running in its own dedicated container. This separation keeps the stack modular, easier to manage, and closer to real-world deployment practices.

### 6.1 NGINX

The NGINX container acts as the only public entry point of the infrastructure. Its role is to receive incoming HTTPS requests on port `443`, handle TLS, and forward PHP requests to the WordPress service. In this project, NGINX must use only TLSv1.2 or TLSv1.3 and must be the only service exposed to the outside.

Main responsibilities of this service:

- serve as the public web server,
- terminate HTTPS connections,
- forward dynamic PHP requests to the WordPress container,
- restrict public access to a single secure entry point.

### 6.2 WordPress + php-fpm

The WordPress container provides the application itself. It contains the WordPress files and runs `php-fpm` to process PHP code. It does not include NGINX, since the web server and the PHP runtime must remain separated into different services.

Main responsibilities of this service:

- host the WordPress application,
- process PHP requests through `php-fpm`,
- connect to the MariaDB service for persistent data,
- store website files in a dedicated named volume.

### 6.3 MariaDB

The MariaDB container provides the database backend for WordPress. It stores application data such as posts, pages, settings, and user information. This service is isolated from public access and communicates only through the internal Docker network.

Main responsibilities of this service:

- store the WordPress database,
- provide persistent relational storage,
- manage application data independently from the web layer,
- store database files in a dedicated named volume.

### 6.4 Service Interaction

These services work together as a single application:

1. A client connects to `https://<login>.42.fr`
2. NGINX receives the HTTPS request on port `443`
3. PHP requests are forwarded to the WordPress container
4. WordPress communicates with MariaDB through the internal Docker network
5. Persistent data is stored in Docker named volumes

This design ensures that each service has a clear role while remaining connected through Docker Compose and the project’s internal network.

---

## 7. Data Persistence

Data persistence is an essential part of the project because the infrastructure must preserve important information even if containers are stopped, removed, or rebuilt. In Inception, persistence is handled through Docker named volumes rather than storing data directly inside containers.

Two named volumes are required in the mandatory part of the project:

- one volume for the WordPress website files,
- one volume for the MariaDB database files.

This separation ensures that application files and database data are stored independently and remain available across container restarts or recreation. Without persistent volumes, all stored data would be lost whenever a container is removed.

According to the project requirements, both named volumes must store their data inside `/home/<login>/data` on the host machine. This makes the persistent data easier to locate and inspect while still allowing Docker to manage it through volumes rather than bind mounts.

Using named volumes also improves the maintainability of the infrastructure. Containers can be rebuilt or updated without losing the WordPress site files or the database content. This is especially important for MariaDB, where losing the database volume would mean losing posts, users, settings, and all other stored website data.

In practice, persistence in this project allows:

- WordPress content to remain available after restarting the stack,
- database records to survive container recreation,
- website files to stay stored independently from the running container,
- safer updates and rebuilds during development and testing.

This design follows the project requirements and reflects a common containerization principle: containers should remain replaceable, while important application data should live outside them in persistent storage.

---

## 8. Security Notes

Security is an important part of the Inception project because the infrastructure includes a public web server, application logic, and persistent database storage. Even in a local development environment, the stack must be configured in a way that reduces unnecessary exposure and follows safer deployment practices.

One of the main security measures in this project is that NGINX is the only public entry point. External traffic must go through port `443` only, using HTTPS with TLSv1.2 or TLSv1.3. This limits direct exposure of the internal services and ensures that communication with the website is encrypted.

The WordPress and MariaDB services are not meant to be exposed directly to the outside. Instead, they communicate only through the internal Docker network. This design reduces the attack surface by keeping the database and PHP application layer isolated from direct public access.

Another important rule is the handling of credentials. Passwords and other sensitive values must not be written directly inside Dockerfiles. General configuration can be stored in environment variables through the `.env` file, but confidential values should be kept outside version control and managed carefully through local secret files or other secure methods.

The project also benefits from service separation. Running NGINX, WordPress, and MariaDB in dedicated containers makes the infrastructure easier to control and audit. Each service has a clearly defined role, which reduces unnecessary dependencies and keeps the overall design more predictable.

From a persistence perspective, storing important data in named volumes also contributes to safer management. Data remains available independently of the container lifecycle, which avoids risky workarounds and makes rebuilds or updates less destructive.

Overall, the security approach of this project relies on a few core principles: limiting public exposure, encrypting external traffic, isolating internal services, avoiding hardcoded credentials, and keeping persistent data separate from container images.

---

## 9. Resources

### 9.1 Official documentation
- [Docker Docs — Compose overview](https://docs.docker.com/compose/)
- [Docker Docs — Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker Docs — Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Docs — Docker build best practices](https://docs.docker.com/build/building/best-practices/)
- [Docker Docs — Networking](https://docs.docker.com/engine/network/)
- [Docker Docs — Storage: volumes and bind mounts](https://docs.docker.com/engine/storage/)
- [Docker Docs — Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX Docs — Configuring HTTPS servers](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [NGINX Docs — `ngx_http_ssl_module`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [WordPress Developer Docs — NGINX / php-fpm setup notes](https://developer.wordpress.org/advanced-administration/server/web-server/nginx/)
- [MariaDB Docs — MariaDB in Docker and environment variables](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/mariadb-server-docker-official-image-environment-variables)

---

### 9.2 How AI was used
AI was used for:
- summarizing subject requirements,
- helping draft documentation structure,
- comparing Docker concepts for the README,
- suggesting learning resources.

> All generated explanations, commands, and design notes were reviewed manually, tested in the project context, and rewritten when necessary to ensure full understanding.

