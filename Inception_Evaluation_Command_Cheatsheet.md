# INCEPTION — EVALUATION COMMAND CHEAT SHEET

**For mjusta / Debian 12 VM / `~/Downloads/Inception`**  
Use this **in order** during a live demonstration. Commands are deliberately short. Commands labelled *optional* are useful if an evaluator asks for proof. This is based on the evaluation-sheet screenshot, the uploaded subject, and the functionality you already tested. Adjust paths if your submitted clone lives elsewhere.

## 0 — Open the project and launch

```bash
cd ~/Downloads/Inception
pwd
ls -la
make
cd srcs
docker compose ps
```

**Show:** Makefile at root, `srcs/docker-compose.yml`, eight running services. If already running, `make` should be safe to repeat if your Makefile supports it. **Do not run `make fclean` during the demo:** it might delete your data, depending on your Makefile.

## 1 — VM, Docker and project layout

```bash
whoami
cat /etc/os-release
docker --version
docker compose version
cd ~/Downloads/Inception
ls
find srcs -name Dockerfile
```

**Say:** “The project runs inside a Debian VM. Docker Compose builds my own service images using one Dockerfile per service.” Show the `FROM` lines to explain the Debian/Alpine base:

```bash
grep -R '^FROM ' srcs/requirements --include=Dockerfile
```

## 2 — Image names, restart policies, network and ports

```bash
cd ~/Downloads/Inception/srcs
docker compose ps
docker images
docker network ls
docker compose config --services
```

Show Compose source:

```bash
less docker-compose.yml
```

For one container's network and restart policy:

```bash
docker inspect nginx --format '{{.HostConfig.RestartPolicy.Name}}'
docker inspect nginx --format '{{json .NetworkSettings.Networks}}'
```

**Say:** “Each service has its own container; Compose defines the shared Docker network. MariaDB, Redis and PHP-FPM have internal ports, not host-published ports.” Bonus services intentionally publish additional ports.

**Important image-tag question:** `docker images` shows `:latest` when an `image:` value omits a tag. Your Compose currently says `image: nginx`, etc.; do not claim this is conclusively compliant with the subject's prohibition on the `latest` tag. Decide whether to add explicit non-`latest` tags before submission.

## 3 — NGINX, HTTPS and domain

```bash
getent hosts mjusta.42.fr
curl -k -I https://mjusta.42.fr
```

Open in the VM browser: **https://mjusta.42.fr**. Show the WordPress home page.

TLS test (success expected for 1.2 and 1.3; failure expected for 1.0 and 1.1):

```bash
openssl s_client -connect mjusta.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect mjusta.42.fr:443 -tls1_3 </dev/null
openssl s_client -connect mjusta.42.fr:443 -tls1 </dev/null
openssl s_client -connect mjusta.42.fr:443 -tls1_1 </dev/null
```

**Quick version:**

```bash
curl -k -I https://mjusta.42.fr
```

**Say:** “NGINX is the HTTPS entry point for the mandatory WordPress stack; it forwards PHP requests to WordPress/PHP-FPM over Docker networking.” If asked, show the NGINX config in `srcs/requirements/nginx/conf/` and the browser certificate information.

## 4 — WordPress + PHP-FPM + two accounts

```bash
docker exec wordpress wp core is-installed --allow-root && echo 'WP installed'
docker exec wordpress wp user list --allow-root
```

**Show:** `Aztaban` is administrator; `JohnDoe` is author. Open **https://mjusta.42.fr/wp-admin/** and log in privately (never display or read passwords aloud). Show Posts / Users. WordPress is served by NGINX, not an NGINX server inside the WordPress container.

## 5 — MariaDB and the two volumes

```bash
docker exec wordpress wp db check --allow-root
docker volume ls
ls -lah /home/mjusta/data
```

Optional: demonstrate volume source and target without dumping credentials:

```bash
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

**Say:** “MariaDB stores WordPress database tables; the second named volume stores WordPress files. Both persist on the VM under `/home/mjusta/data`.” Show the `volumes:` definitions in Compose.

## 6 — Persistence demonstration (safe, no deletion)

Before the evaluation, create a distinctive **published test post** in the WordPress dashboard, e.g. “Inception persistence demo”. Show it in the browser. Then:

```bash
cd ~/Downloads/Inception/srcs
docker compose down
make -C ..
docker compose ps
```

Reload the post. **It should still exist.** `docker compose down` without `-v` preserves named volumes. **Do not use `down -v`, `docker volume prune`, or `make fclean` unless you have inspected their exact effects.** If the evaluator only needs the proof, explain the previously performed persistence test rather than interrupting the demo.

## 7 — Redis bonus

```bash
docker exec redis redis-cli ping
docker exec wordpress wp redis status --allow-root
```

**Expected:** `PONG`, and WordPress Redis status reports **Connected**. Open WordPress and refresh; Redis caching is integrated with WordPress.

## 8 — FTP bonus

```bash
curl --user mjusta ftp://127.0.0.1/
```

Curl prompts for the password. **Do not use `-v` when demonstrating credentials.** Show WordPress files in FTP listing. To demonstrate actual write/read/delete:

```bash
echo 'FTP demo' > /tmp/ftp_test.txt
curl --user mjusta -T /tmp/ftp_test.txt ftp://127.0.0.1/wp-content/uploads/ftp_test.txt
docker exec wordpress cat /var/www/html/wp-content/uploads/ftp_test.txt
curl --user mjusta -Q 'DELE /wp-content/uploads/ftp_test.txt' ftp://127.0.0.1/
docker exec wordpress test ! -e /var/www/html/wp-content/uploads/ftp_test.txt && echo 'Deleted'
```

**Say:** “FTP and WordPress share the same named WordPress-files volume.”

## 9 — Adminer bonus

Open **http://localhost:8080**. Log in privately with the MariaDB **application user**, the configured DB name, and server **`mariadb`** (not `localhost`). Show `wp_users` and `wp_posts`; do not edit records.

```bash
curl -I http://localhost:8080
```

## 10 — Static site bonus

Open **http://localhost:8081**. Show the actual static page and its source files.

```bash
curl -I http://localhost:8081
```

**Say:** “This is a separate static site, not a PHP/WordPress site.”

## 11 — Glances bonus

Open **http://localhost:61208** and show CPU, memory, disk and processes.

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:61208/
```

**Expected:** `200`. `curl -I` uses HEAD and returned `405` in your setup, so use a normal GET.

**Say:** “Glances helps me monitor VM/container resource use and investigate issues such as the VM freeze.”

## 12 — Secrets, Git and docs (do not print secrets)

```bash
cd ~/Downloads/Inception
git status --short
git ls-files | grep -E '(^|/)(secrets/|\.env$)'
ls README.md USER_DOC.md DEV_DOC.md
cat .gitignore
```

**Expected:** the tracked-file grep prints **nothing** for real secrets and `.env`. Avoid `cat srcs/.env`, `cat secrets/*`, `docker compose config` or verbose authentication logs on screen: these may expose credentials.

## 13 — Resource check if VM slows or freezes

```bash
free -h
df -h /
docker stats --no-stream
```

## The five commands to remember first

```bash
make
docker compose ps
curl -k -I https://mjusta.42.fr
docker exec wordpress wp user list --allow-root
docker volume ls
```

**Final note:** Functionality has been demonstrated on the prepared VM. A clean-clone build, full source audit, and the exact evaluator's current interpretation of image tags remain separate checks.
