# DEV_DOC.md

## Environment Setup From Scratch

This document explains how to set up, build, launch, and maintain the Inception project as a developer.

The project is intended to run on a Debian-based virtual machine.

### Prerequisites

The host machine must have the following tools installed:

- curl
- Make
- Docker
- Docker Compose v2

```bash
sudo apt install -y make curl
curl -fsSL https://get.docker.com | sh
```

On Debian 12, install the required tools according to your Docker installation method. After installation, verify that Docker, Docker Compose v2, and Make are available:

```bash
docker --version
docker compose version
make --version
```

Check that Docker is running:

```bash
sudo systemctl status docker
```

If the current user is not allowed to run Docker commands directly, either use `sudo` with Docker commands or add the user to the `docker` group:

```bash
sudo /usr/sbin/usermod -aG docker $USER
```

After adding the user to the `docker` group, log out and log back in for the change to take effect.

All application services are installed inside their own Docker images by the project Dockerfiles. The host machine only needs Docker, Docker Compose v2, and Make.

---

## Configuration Files

The main configuration file is:

```text
srcs/.env
```

This file contains non-secret environment variables used by Docker Compose and the containers.

Example values:

```env
DOMAIN_NAME=<login>.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_ADMIN_USER=<wordpress_admin_username>
WP_ADMIN_EMAIL=<wordpress_admin_email>
WP_USER=<wordpress_regular_username>
WP_USER_EMAIL=<wordpress_regular_email>
```

Replace `<login>` with the 42 login used for the project.

The domain name must follow this format:

```text
<login>.42.fr
```

The domain must point to the local VM IP address. This can be configured in `/etc/hosts` on the host machine:

```text
127.0.0.1 <login>.42.fr
```

or, if accessing the VM from another machine:

```text
<VM_IP_ADDRESS> <login>.42.fr
```

Do not store passwords directly in `.env`.

---

## Secrets Setup

Passwords are stored in separate files inside the `secrets/` directory.

Each secret file must contain only the raw password value, with no variable name and no extra text.

Example:

```text
my_secure_password
```

A typical setup uses files such as:

```text
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

The exact filenames must match the names referenced in `srcs/docker-compose.yml`.

Example Docker Compose secret definition:

```yaml
secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt
  db_password:
    file: ../secrets/db_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
```

The `secrets/` directory must not be committed to Git.

Add it to `.gitignore`:

```gitignore
secrets/
```

---

## Building and Launching the Project

The project is managed from the repository root using the Makefile.

Build and start the infrastructure:

```bash
make
```

or:

```bash
make all
```

The Makefile should call Docker Compose v2 using the Compose file inside `srcs/`.

Example Makefile variable:

```makefile
COMPOSE = docker compose -f srcs/docker-compose.yml
```

A typical `all` rule:

```makefile
all:
	$(COMPOSE) up -d --build
```

The containers can also be launched manually with Docker Compose v2:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

If running commands from inside the `srcs/` directory, use:

```bash
cd srcs
docker compose up -d --build
```

---

## Managing Containers

Show running containers:

```bash
make ps
```

or manually:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Show logs for all services:

```bash
make logs
```

or manually:

```bash
docker compose -f srcs/docker-compose.yml logs
```

Show logs for a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Follow logs live:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Stop the containers without deleting volumes:

```bash
make down
```

or manually:

```bash
docker compose -f srcs/docker-compose.yml down
```

Rebuild the containers:

```bash
make re
```

or manually:

```bash
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d --build
```

Enter a running container:

```bash
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

Depending on the base image and installed packages, `bash` may not be available. Use `sh` when needed.

---

## Managing Volumes

List Docker volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume_name>
```

Stop containers and keep volumes:

```bash
docker compose -f srcs/docker-compose.yml down
```

Stop containers and remove volumes:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

A full cleanup target may remove containers, networks, images, and volumes depending on the Makefile implementation.

Before deleting volumes, make sure that the stored WordPress website files and MariaDB database data are no longer needed.

---

## Data Storage and Persistence

The project uses Docker named volumes for persistent data.

The mandatory persistent data is:

- WordPress database data
- WordPress website files

The data must be stored on the host machine under:

```text
/home/<login>/data
```

A common layout is:

```text
/home/<login>/data/mariadb
/home/<login>/data/wordpress
```

The MariaDB volume stores the database files. This allows the WordPress database to persist even if the MariaDB container is stopped, removed, or rebuilt.

The WordPress volume stores the website files. This allows WordPress files, uploaded media, themes, and plugins to persist even if the WordPress container is stopped, removed, or rebuilt.

The containers themselves are disposable. Persistent project data should live in the named volumes, not inside the container filesystem.

---

## Testing the Project

Check that all containers are running:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Only the NGINX container should expose port `443` on the host:

```bash
docker ps
```

Test HTTPS access:

```bash
curl -k -I https://<login>.42.fr
```

A working setup should return an HTTP response from NGINX, usually `200 OK` or a valid redirect.

Open the website in a browser:

```text
https://<login>.42.fr
```

Open the WordPress administration page:

```text
https://<login>.42.fr/wp-admin
```

Check the mounted data directory on the host:

```bash
ls -la /home/<login>/data
```

Check the logs if something is not working:

```bash
docker compose -f srcs/docker-compose.yml logs --tail=100
```

---

## Bonus Services

If bonus services are added, each bonus service must have its own Dockerfile and run in its own container.

Bonus services may include, for example:

- Redis cache
- FTP server
- Adminer
- Static website
- Another justified service

Each bonus service should be declared in `srcs/docker-compose.yml` and connected to the appropriate Docker network.

If a bonus service needs persistent data, it should use its own dedicated Docker volume.

If a bonus service needs to expose a port, the port mapping must be declared explicitly in `srcs/docker-compose.yml`.

Bonus services should not break the mandatory requirement that NGINX is the only entrypoint for the mandatory WordPress infrastructure through port `443`.