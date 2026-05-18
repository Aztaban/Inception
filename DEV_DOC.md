# DEV_DOC.md

## Environment Setup From Scratch

This document explains how to set up, build, launch, debug, and maintain the Inception project as a developer.

The project is intended to run inside a Debian-based virtual machine. The host machine should stay minimal: project services are installed inside their own Docker images using the project Dockerfiles.

### Prerequisites

Install Make, Curl, Docker, and Docker Compose v2:

```bash
sudo apt update
sudo apt install -y make curl
curl -fsSL https://get.docker.com | sh
```

Verify the installation:

```bash
docker --version
docker compose version
make --version
```

Check that Docker is running:

```bash
sudo systemctl status docker
```

If Docker is not running, start it:

```bash
sudo systemctl start docker
```

To start Docker automatically after boot:

```bash
sudo systemctl enable docker
```

If the current user cannot run Docker commands directly, either use `sudo` with Docker commands or add the user to the `docker` group:

```bash
sudo /usr/sbin/usermod -aG docker $USER
```

After adding the user to the `docker` group, log out and log back in for the change to take effect.

All application services are installed inside their own Docker images by the project Dockerfiles. The host machine only needs Docker, Docker Compose v2, and Make.

---

## Configuration Files

The main environment configuration file is:

```text
srcs/.env
```

This file contains non-secret environment variables used by Docker Compose and the containers.

Example values:

```env
DOMAIN_NAME=mjusta.42.fr
DATA_PATH=/home/mjusta/data

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

WP_ADMIN_USER=wp_owner
WP_ADMIN_EMAIL=owner@example.com
WP_USER=wp_author
WP_USER_EMAIL=author@example.com

FTP_USER=ftpuser
```

For this project:

```text
mjusta.42.fr
```

The domain must point to the local VM IP address. This can be configured in `/etc/hosts`.

Inside the VM, this is usually enough:

```text
127.0.0.1 mjusta.42.fr
```

If accessing the VM from the host machine, use the VM IP address:

```text
<VM_IP_ADDRESS> mjusta.42.fr
```

Do not store passwords in `.env`.

---

## Secrets Setup

Passwords are stored in separate files inside the `secrets/` directory.

Each secret file should contain only the raw password value, with no variable name and no extra text.

Example:

```text
my_secure_password
```

Common secret files:

```text
secrets/db_root_password.txt
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
secrets/ftp_password.txt
```ts/wp_user_password.txt
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
  ftp_password:
    file: ../secrets/ftp_password.txt
```

The `secrets/` directory must not be committed to Git.

Add it to `.gitignore`:

```gitignore
secrets/
```

Credentials should never be written directly inside Dockerfiles or committed to the repository.

---

## Persistent Data Directories

The mandatory persistent data is stored under:

```text
/home/mjusta/data
```

The expected layout is:

```text
/home/mjusta/data/mariadb
/home/mjusta/data/wordpress
```

The Makefile creates these directories before starting the stack:

```makefile
sudo mkdir -p /home/mjusta/data/mariadb
sudo mkdir -p /home/mjusta/data/wordpress
```

The MariaDB volume stores database files. The WordPress volume stores website files, uploaded media, plugins, and themes.

The containers are disposable. Important data should live in Docker named volumes backed by these host paths, not only inside the container filesystem.

---

## Building and Launching the Project

The project is managed from the repository root using the Makefile.

Start the full stack:

```bash
make
```

or:

```bash
make all
```

The Makefile uses Docker Compose v2 with:

```makefile
COMPOSE_FILE = srcs/docker-compose.yml
```

The main startup rule creates persistent data directories and launches the stack:

```makefile
up:
	sudo mkdir -p /home/mjusta/data/mariadb
	sudo mkdir -p /home/mjusta/data/wordpress
	docker compose -f $(COMPOSE_FILE) up --build -d
```

The equivalent manual command is:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

---

## Makefile Commands

Start or build the project:

```bash
make
make up
```

Stop and remove containers while keeping images and host data:

```bash
make down
```

Stop containers without removing them:

```bash
make stop
```

Start stopped containers:

```bash
make start
```

Restart the stack:

```bash
make restart
```

Show logs:

```bash
make logs
```

Show container status:

```bash
make ps
```

Remove containers, project volumes, and orphan containers:

```bash
make clean
```

Full cleanup, including project images and local persistent data:

```bash
make fclean
```

Rebuild from scratch:

```bash
make re
```

Be careful with `make fclean`: it removes `/home/mjusta/data/mariadb` and `/home/mjusta/data/wordpress`, which deletes the local persistent database and WordPress files.

---

## Managing Containers Manually

Show project containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Show all running containers:

```bash
docker ps
```

Show all containers, including stopped ones:

```bash
docker ps -a
```

Show logs for all services:

```bash
docker compose -f srcs/docker-compose.yml logs
```

Follow logs live:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Show logs for one service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs redis
docker compose -f srcs/docker-compose.yml logs adminer
docker compose -f srcs/docker-compose.yml logs ftp
docker compose -f srcs/docker-compose.yml logs static_site
docker compose -f srcs/docker-compose.yml logs glances
```

Enter a running container:

```bash
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

Depending on the installed packages, `bash` may not be available. Use `sh` when needed.

---

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

Stop containers and remove Docker Compose volumes:

```bash
docker compose -f srcs/docker-compose.yml down --volumes
```

Check the host data directories:

```bash
ls -la /home/mjusta/data
ls -la /home/mjusta/data/mariadb
ls -la /home/mjusta/data/wordpress
```

Before deleting volumes or host data, make sure the stored WordPress website files and MariaDB database data are no longer needed.

---

## Mandatory Services

### NGINX

NGINX is the only public entrypoint for the mandatory WordPress infrastructure.

It listens on:

```text
443
```

It handles HTTPS with TLSv1.2 or TLSv1.3 and forwards PHP requests to the WordPress PHP-FPM service.

The website should be accessible at:

```text
https://mjusta.42.fr
```

### WordPress + PHP-FPM

The WordPress container contains WordPress and PHP-FPM only. It does not contain NGINX.

It connects to MariaDB through the internal Docker network using the MariaDB service name.

It stores website files in the WordPress persistent volume.

### MariaDB

MariaDB stores the WordPress database.

It is not exposed publicly. WordPress connects to it through the internal Docker network.

MariaDB database data is stored in the MariaDB persistent volume.

---

## Bonus Services

Each bonus service has its own Dockerfile and runs in its own container.

Current bonus services:

```text
Redis
Adminer
FTP
Static website
Glances
```

### Redis

Redis is used as an object cache for WordPress.

It is connected only to the internal Docker network and does not need a public port.

Useful checks:

```bash
docker exec -it redis redis-cli ping
docker exec -it wordpress wp redis status --allow-root
```

Expected Redis ping response:

```text
PONG
```

### Adminer

Adminer is a lightweight database administration interface for MariaDB.

It is exposed on:

```text
http://localhost:8080
```

If accessing from outside the VM, use:

```text
http://<VM_IP_ADDRESS>:8080
```

Login values:

```text
System:   MySQL
Server:   mariadb
Username: MYSQL_USER from srcs/.env
Password: db_password secret
Database: MYSQL_DATABASE from srcs/.env
```

### FTP

FTP gives administrator access to the WordPress website files by mounting the same WordPress volume.

It uses:

```text
Port 21
Passive ports 21100-21110
```

The FTP username is stored in `srcs/.env`, and the password is stored in:

```text
secrets/ftp_password.txt
```

The FTP container should mount:

```text
wordpress_data:/var/www/html
```

### Static Website

The static website is an independent bonus web service served from its own container.

It is exposed on:

```text
http://localhost:8081
```

If accessing from outside the VM, use:

```text
http://<VM_IP_ADDRESS>:8081
```

It must not use PHP.

### Glances

Glances is the custom service of choice. It provides a lightweight web interface for monitoring system resource usage.

It is exposed on:

```text
http://localhost:61208
```

If accessing from outside the VM, use:

```text
http://<VM_IP_ADDRESS>:61208
```

It is built from Debian using the project Dockerfile, not from a ready-made Glances image.

---

## Testing the Project

Check that all containers are running:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Check exposed ports:

```bash
docker ps
```

For the mandatory part, NGINX should be the only public entrypoint to the WordPress website through port `443`.

Bonus services may expose extra ports:

```text
Adminer:       8080
Static site:   8081
FTP:           21 and 21100-21110
Glances:       61208
```

Test HTTPS access:

```bash
curl -k -I https://mjusta.42.fr
```

A working setup should return an HTTP response from NGINX, usually `200 OK` or a valid redirect.

Open the website in a browser:

```text
https://mjusta.42.fr
```

Open the WordPress administration page:

```text
https://mjusta.42.fr/wp-admin
```

Test Redis:

```bash
docker exec -it redis redis-cli ping
```

Test Adminer:

```text
http://localhost:8080
```

Test the static website:

```text
http://localhost:8081
```

Test Glances:

```text
http://localhost:61208
```

Check FTP with an FTP client:

```text
Host: localhost
Port: 21
User: value of FTP_USER
Password: value from secrets/ftp_password.txt
```

---

## Common Troubleshooting

### Docker command requires permission

If Docker commands fail with a permission error, either run them with `sudo` or add the user to the `docker` group:

```bash
sudo /usr/sbin/usermod -aG docker $USER
```

Then log out and log back in.

### Domain does not resolve

Check `/etc/hosts`:

```bash
cat /etc/hosts
```

For local VM access, it should contain something like:

```text
127.0.0.1 mjusta.42.fr
```

For host-to-VM access, it should contain:

```text
<VM_IP_ADDRESS> mjusta.42.fr
```

### Website does not open

Check containers:

```bash
docker ps
```

Check NGINX logs:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
```

Test HTTPS with curl:

```bash
curl -k -I https://mjusta.42.fr
```

The `-k` option is needed because the TLS certificate is self-signed.

### WordPress cannot connect to MariaDB

Check logs:

```bash
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Check that the database variables in `srcs/.env` match the values used by the MariaDB and WordPress scripts.

If MariaDB was already initialized, changing secret files later may not update the existing database credentials. During development, a full data reset may be required.

### Redis is not active in WordPress

Check Redis:

```bash
docker exec -it redis redis-cli ping
```

Check WordPress Redis status:

```bash
docker exec -it wordpress wp redis status --allow-root
```

Check that the Redis Object Cache plugin was installed and enabled during WordPress initialization.

### Adminer cannot connect to MariaDB

In Adminer, use:

```text
Server: mariadb
```

Do not use:

```text
localhost
```

`localhost` would refer to the Adminer container itself, not the MariaDB container.

### FTP login works but directory listing hangs

Check the passive FTP configuration.

If connecting from inside the VM, `pasv_address=127.0.0.1` may be enough.

If connecting from the host machine to the VM, set `pasv_address` in the FTP configuration to the VM IP address and rebuild the FTP image.

### Data disappeared

Check host data directories:

```bash
ls -la /home/mjusta/data/mariadb
ls -la /home/mjusta/data/wordpress
```

If `make fclean` was used, the local persistent data directories may have been removed.

---

## Development Notes

Do not use ready-made service images for project services. Each service should be built from its own Dockerfile, using Debian or Alpine as the base image.

Do not use the `latest` tag for service images.

Do not put passwords in Dockerfiles.

Do not use container hacks such as:

```text
tail -f
sleep infinity
while true
```

The main service process should run in the foreground, usually using `exec` in the init script.

Examples:

```bash
exec nginx -g "daemon off;"
exec php-fpm8.2 -F
exec redis-server /etc/redis/redis.conf
exec /usr/sbin/vsftpd /etc/vsftpd.conf
exec glances -w --bind 0.0.0.0 --port 61208
```

Keep mandatory and bonus responsibilities separate. The mandatory WordPress infrastructure should remain reachable through NGINX on port `443`, while bonus services may expose their own ports when needed.
