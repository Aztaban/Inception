# User Documentation

## Overview

This document explains how to use the Inception stack as an end user or administrator.

The project provides a small Docker-based infrastructure running inside a virtual machine. The mandatory stack contains:

- **NGINX** as the only public entrypoint, available through HTTPS on port `443`
- **WordPress** running with PHP-FPM
- **MariaDB** as the WordPress database
- **Docker named volumes** for persistent database and website data
- **A Docker network** used for communication between containers

The project also includes optional bonus services. These services are separate from the mandatory infrastructure.

- **Redis** for WordPress object caching
- **Adminer** for database inspection
- **FTP** for access to the WordPress website files
- **Static website** as an additional independent web service
- **cAdvisor** for container monitoring

---

## Services

### NGINX

NGINX is the public entrypoint of the infrastructure.

It listens on:

```text
https://mjusta.42.fr
```

Only port `443` is exposed for the mandatory part. HTTP port `80` is not used.

NGINX uses TLS and forwards PHP requests to the WordPress container.

### WordPress

WordPress provides the website and administration panel.

It runs with PHP-FPM and does not contain NGINX. It stores website files in the WordPress persistent volume.

### MariaDB

MariaDB stores the WordPress database.

It is not publicly exposed. WordPress connects to MariaDB through the private Docker network.

### BONUS Redis  
Redis is an in-memory data store used as a caching service for WordPress. It helps reduce repeated database queries by storing frequently requested objects in memory, which can improve the performance and responsiveness of the website.

### BONUS Adminer  
Adminer is a lightweight database management tool. It provides a web interface for inspecting and managing the MariaDB database, making it easier to check WordPress tables, users, and persisted data during development and administration.

### BONUS FTP  
The FTP service provides file access to the WordPress website volume. It allows an administrator to upload, download, or inspect WordPress files without entering the container directly.

### BONUS Static website
The static website is an additional independent web service served from its own container. It can be used as a simple portfolio, project presentation page, or landing page, and demonstrates how the infrastructure can host more than one type of web application.

### BONUS cAdvisor
cAdvisor is a container monitoring service. It provides information about running containers, including CPU usage, memory usage, network activity, and filesystem usage, which helps with observing and debugging the Docker infrastructure.

---

## Starting the Project

From the root of the repository, run:

```bash
make
```

or:

```bash
make up
```

This command creates the required data directories, builds the Docker images, and starts the containers.

After starting the project, check that the containers are running:

```bash
make ps
```

or:

```bash
docker-compose -f srcs/docker-compose.yml ps
```

Expected mandatory containers:

```text
mariadb
wordpress
nginx
```

---

## Stopping the Project

To stop and remove the running containers while keeping persistent data:

```bash
make down
```

To stop containers without removing them:

```bash
make stop
```

To start stopped containers again:

```bash
make start
```

To restart the full stack:

```bash
make restart
```

---

## Accessing the Website

The website is available at:

```text
https://mjusta.42.fr
```

Because the project uses a self-signed TLS certificate, the browser may show a security warning. This is expected in a local development environment.

To continue, accept the browser warning and proceed to the site.

If the domain does not resolve, check that the host machine or VM has an `/etc/hosts` entry pointing the domain to the correct IP address.

Example inside the VM:

```text
127.0.0.1 mjusta.42.fr
```

Example from the host machine:

```text
<VM_IP_ADDRESS> mjusta.42.fr
```

The VM IP address can be checked with:

```bash
ip a
```

---

## Accessing the WordPress Admin Panel

The WordPress administration panel is available at:

```text
https://mjusta.42.fr/wp-admin
```

Use the WordPress administrator username from:

```text
srcs/.env
```

The administrator password is stored in:

```text
secrets/wp_admin_password.txt
```

The WordPress administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

---

## Credentials

Configuration values are stored in:

```text
srcs/.env
```

Sensitive credentials are stored in the `secrets/` directory.

Common secret files:

```text
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

These files are used by Docker Compose as Docker secrets and are mounted inside containers under:

```text
/run/secrets/
```

Credentials should not be written directly inside Dockerfiles or committed to a public repository.

---

## Persistent Data

The project uses Docker named volumes for persistent data.

The MariaDB database data is stored on the host at:

```text
/home/mjusta/data/mariadb
```

The WordPress website files are stored on the host at:

```text
/home/mjusta/data/wordpress
```

This allows data to survive container restarts and rebuilds.

Stopping the containers with:

```bash
make down
```

does not delete persistent data.

A full cleanup command may remove containers, volumes, images, and local data depending on the Makefile implementation.

---

## Checking Service Status

To list running containers:

```bash
docker ps
```

To check all containers, including stopped ones:

```bash
docker ps -a
```

To check the project status through the Makefile:

```bash
make ps
```

---

## Viewing Logs

To view logs for all services:

```bash
make logs
```

or:

```bash
docker-compose -f srcs/docker-compose.yml logs -f
```

To view logs for a specific service:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

---

## Basic Troubleshooting

### The website does not open

Check that the containers are running:

```bash
docker ps
```

Check that the domain points to the correct IP address:

```bash
cat /etc/hosts
```

Test the site with curl:

```bash
curl -k https://mjusta.42.fr
```

The `-k` option is used because the TLS certificate is self-signed.

### WordPress cannot connect to the database

Check MariaDB logs:

```bash
docker logs mariadb
```

Check WordPress logs:

```bash
docker logs wordpress
```

Make sure the database variables in `srcs/.env` match the values used by WordPress and MariaDB.

### Login does not work

Check the WordPress usernames in:

```text
srcs/.env
```

Check the passwords in:

```text
secrets/
```

If the database or WordPress volume was already initialized, changing the secret files later may not update the existing WordPress or MariaDB credentials. In that case, the persistent data may need to be reset during development.

### Data disappeared

Check that the Docker volumes are using the correct host paths:

```text
/home/mjusta/data/mariadb
/home/mjusta/data/wordpress
```

Also check that the folders exist and contain files:

```bash
ls -la /home/mjusta/data/mariadb
ls -la /home/mjusta/data/wordpress
```

---

## Useful Commands

Start the project:

```bash
make
```

Stop and remove containers:

```bash
make down
```

View logs:

```bash
make logs
```

Show containers:

```bash
make ps
```

Rebuild from scratch according to the Makefile:

```bash
make re
```

Check the website:

```bash
curl -k https://mjusta.42.fr
```

Enter the MariaDB container:

```bash
docker exec -it mariadb bash
```

Enter the WordPress container:

```bash
docker exec -it wordpress bash
```

Enter the NGINX container:

```bash
docker exec -it nginx bash
```