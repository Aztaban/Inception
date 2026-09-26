# INCEPTION — EVALUATION PREPARATION, FLOW AND ANSWERS

**Personal rehearsal guide for mjusta.** Based on the evaluation-sheet screenshot you supplied, the uploaded Inception subject (v5.2), and your tested Debian 12 VM. This is a guide to understanding and demonstrating **your** project, not a substitute for checking its source. The sheet can change; follow the evaluator's actual version on the day.

## Before the evaluator arrives (5–10 minutes)

- [ ] Boot the VM; verify Docker is running and `make` works from `~/Downloads/Inception`.
- [ ] Check `docker compose ps` from `srcs`: all eight services Up.
- [ ] Open **https://mjusta.42.fr** in Firefox and confirm the website loads.
- [ ] Have the WordPress administrator login ready **privately**; never show secret file contents.
- [ ] Have a persistence demo post ready, and know where it appears after a restart.
- [ ] Open tabs: WordPress, `/wp-admin/`, Adminer `:8080`, static site `:8081`, Glances `:61208`.
- [ ] Know where to show your Compose file, Makefile, Dockerfiles, NGINX config and startup scripts.
- [ ] Check `free -h` and `df -h /` because this VM froze once.
- [ ] Check `git status --short` and `git ls-files | grep -E '(^|/)(secrets/|\.env$)'` before submitting.
- [ ] Verify `README.md`, `USER_DOC.md`, `DEV_DOC.md` and local setup instructions.
- [ ] Decide the `:latest` issue before submission: `image: nginx` creates a displayed `nginx:latest` tag even though you did not type `:latest`. The subject prohibits the latest tag; explicit version tags remove ambiguity.

## A natural 60-second introduction

> “My Inception project runs on a Debian 12 virtual machine. Docker Compose builds and starts a container for each service. The mandatory stack is NGINX for HTTPS, WordPress with PHP-FPM, and MariaDB. I use a Docker network for container communication and two persistent named volumes: one for the database and one for WordPress files. My bonuses are Redis, FTP, Adminer, a static website and Glances. I keep real credentials in local files that are not committed to Git.”

Point to `srcs/docker-compose.yml` while speaking. Then **show the website early**, rather than explaining for several minutes without a demonstration.

## Recommended live evaluation order

### 1. Preliminaries and general instructions

**Evaluator may ask:** Is the work in a VM? Can you explain the project? Are you using Docker Compose? Is the Makefile at the root? Are files in `srcs`?

**Do:** `whoami`, `cat /etc/os-release`, `ls`, `less Makefile`, `ls srcs`, `docker compose ps`.

**Say:** “The VM isolates the whole infrastructure. The Makefile is the convenient entry point; it invokes Compose to build and run my own images.” Be ready to explain **each** Makefile target from the actual file. Do not invent targets you do not have.

**Check before evaluation:** The screenshot mentions asking questions about Docker/Compose/VM basics, a simple project change, and general instructions. The exact question or requested modification is not predictable.

### 2. Project overview and browser demonstration

**Do:** Open `https://mjusta.42.fr`, show WordPress, then open `srcs/docker-compose.yml`.

**Say:** “NGINX receives HTTPS on 443. It serves the WordPress site and forwards PHP processing to the WordPress PHP-FPM container. WordPress connects to MariaDB using the service name on the Docker network.”

**If asked ‘why not expose MariaDB or PHP-FPM?’** “They are internal services. They should communicate through the Docker network rather than being published directly on the VM.”

### 3. Docker basics / Dockerfiles

**Evaluator may ask:** What is an image? A container? A Dockerfile? Why one per service? What does `FROM` mean? What does PID 1 do? Why avoid `tail -f` / `sleep infinity`?

**Simple answers:**

- **Image:** the packaged filesystem and startup configuration used to create containers.
- **Container:** a running, isolated instance of an image; it shares the host kernel.
- **Dockerfile:** instructions that build the image (`FROM`, `RUN`, `COPY`, `ENTRYPOINT`/`CMD`).
- **One service per container:** separation of responsibilities, easier maintenance and troubleshooting.
- **`FROM`:** chooses the base image. Show the actual Debian/Alpine base and version used by each Dockerfile; do not guess.
- **PID 1:** the container's main process; it should receive signals and allow the service to stop cleanly. `exec` in startup scripts replaces the shell with the real service process.
- **No fake keep-alive loops:** a container should run its actual service in the foreground, not `tail -f`, `while true` or `sleep infinity`.

**Do:** `find srcs -name Dockerfile`, `grep -R '^FROM ' srcs/requirements --include=Dockerfile`, and show actual `ENTRYPOINT`/`CMD` in the relevant Dockerfile. The subject forbids ready-made service images; Debian/Alpine base images are permitted.

### 4. Docker network

**Evaluator may ask:** Why a custom Docker network? How does WordPress find MariaDB? Why not host networking?

**Say:** “Compose puts the services on a named Docker network. Its internal DNS lets WordPress use the hostname `mariadb`. Host networking would remove this network isolation and is forbidden by the subject.”

**Do:** `docker network ls`, show `networks:` in Compose, then `docker inspect nginx --format '{{json .NetworkSettings.Networks}}'`.

### 5. NGINX and SSL/TLS

**Evaluator may ask:** Why NGINX? Why HTTPS? Why port 443? What is TLS? Why 1.2/1.3 only? How is WordPress reached?

**Say:** “NGINX is the public HTTPS entry point for the mandatory stack. TLS encrypts traffic between the browser and NGINX. My NGINX configuration allows TLS 1.2 and 1.3, not the older protocols. NGINX passes PHP requests to PHP-FPM over the Docker network.”

**Do:** show browser at `https://mjusta.42.fr`, `curl -k -I https://mjusta.42.fr`, and NGINX configuration. If asked, demonstrate `openssl s_client` protocol tests from the command cheat sheet.

**Why `-k`?** “My local development certificate is not necessarily trusted by curl. `-k` skips certificate trust verification for this test; it does **not** prove the certificate is publicly trusted.”

**Domain:** `getent hosts mjusta.42.fr`; explain your `/etc/hosts` mapping to the VM's local website.

### 6. WordPress + PHP-FPM + two users

**Evaluator may ask:** Why PHP-FPM? Why isn't NGINX installed in the WordPress container? What are the two users? Can the author administer the site?

**Say:** “PHP-FPM executes WordPress PHP code. NGINX handles HTTP/TLS separately. I created an administrator named `Aztaban` and an author named `JohnDoe`; the admin name does not contain ‘admin’.”

**Do:** `docker exec wordpress wp user list --allow-root`, open `/wp-admin/` and show Users/Posts. Demonstrate the author role only if asked and you can log in privately.

**Know your initialization:** locate and read your actual WordPress setup script. Explain when WordPress is downloaded, how `wp-config.php` is created, how installation avoids repeating on restarts, and how the users are created. Do not assume implementation details beyond what your script shows.

### 7. MariaDB and volumes

**Evaluator may ask:** Where is the database? Why two volumes? What survives `docker compose down`? Named volume vs bind mount?

**Say:** “The database and WordPress files have separate persistent Docker named volumes. Compose mounts them into their respective containers. Their backing data is configured under `/home/mjusta/data` on the VM. Removing and recreating containers does not erase the named volumes.”

**Do:** `docker exec wordpress wp db check --allow-root`, `docker volume ls`, `ls /home/mjusta/data`, `docker volume inspect srcs_mariadb_data` and `docker volume inspect srcs_wordpress_data`.

**Important nuance:** Your named volumes use local-driver bind-backed storage (`driver_opts`), as verified earlier. If asked, explain that the containers reference **Docker named volumes**; the volume driver maps their host storage to `/home/mjusta/data`. Do not call the Compose service mounts plain host bind mounts.

### 8. Persistence test

**Do:** show a known published post. Run `docker compose down` from `srcs`, then `make -C ..` to restart; reload the post. If this is too disruptive during the defense, explain the exact test you performed and show the saved post.

**Say:** “Container lifecycle and persistent data lifecycle are separate. I did not use `down -v`, which would remove named volumes.”

**If asked about reboot:** “After my VM reboot, all eight containers came back Up.” Also show the `restart:` policy in Compose. A VM reboot is **not** the same as a container crash test.

### 9. Secrets and environment variables

**Evaluator may ask:** Why `.env`? Why Docker secrets? Are passwords committed? What is the difference between config and confidential data?

**Say:** “`.env` supplies configuration variables to Compose; the secret files hold confidential values and are mounted read-only into containers. The real `.env` and secrets are created locally on the VM and ignored by Git. I never hard-code passwords in Dockerfiles.”

**Do:** show the **names and mount paths only** in Compose and `git ls-files | grep -E '(^|/)(secrets/|\.env$)'`. Do not print passwords, `docker compose config`, secret file contents or full `curl -v` FTP logs.

**Fresh-clone question:** “The evaluator needs to create the documented local `.env` and secret files before running `make`.” Verify your docs actually explain this.

### 10. Bonus: demonstrate only after mandatory works

The subject says bonus is evaluated only if the mandatory part is complete.

**Redis:** `docker exec redis redis-cli ping` → `PONG`; `docker exec wordpress wp redis status --allow-root` → Connected. “Redis caches WordPress data in memory to reduce repeated database work.”

**FTP:** `curl --user mjusta ftp://127.0.0.1/`; upload a harmless test file to `wp-content/uploads`, read it inside WordPress, then delete it. “FTP and WordPress use the same website-files volume.”

**Static site:** open `http://localhost:8081`; show its HTML/CSS source. “This is a separate non-PHP site.”

**Adminer:** open `http://localhost:8080`, log in privately with server `mariadb`, show WP tables. “Adminer is a browser interface to manage MariaDB.”

**Glances (chosen extra service):** open `http://localhost:61208`; show CPU/RAM/disk. “I chose Glances because a monitoring dashboard helps me diagnose resource pressure in a VM with multiple containers.” Use a GET curl test, not `curl -I`, because HEAD returned 405 in your setup.

### 11. Documentation

**Evaluator may ask:** Can a new user install this? How do they manage credentials? Where are data and logs? Why these design choices?

**Show:** `README.md`, `USER_DOC.md`, `DEV_DOC.md` at repository root.

**README:** first italicized 42 curriculum line; description, instructions, resources and AI-use disclosure; VM vs Docker, secrets vs environment variables, Docker network vs host network, named volumes vs bind mounts.

**USER_DOC:** services, start/stop, website and admin access, credentials, health checks.

**DEV_DOC:** prerequisites, fresh setup, local `.env` and secrets, Makefile/Compose, container/volume commands and persistence paths.

### 12. If the evaluator requests a small change

1. Repeat the requested change back in your own words.
2. Find the exact file (`grep -R`, `find`, `less`).
3. Explain what the current code does before changing it.
4. Make the smallest possible edit.
5. Rebuild/restart only the affected service if possible: `docker compose up -d --build SERVICE`.
6. Show the behavior changed and existing services still work.

Never bluff. If you don't know, inspect the file and explain what you discover.

## Rapid-fire answers to memorize

| Question | Short answer |
|---|---|
| VM vs Docker? | VM virtualizes a full OS/kernel; containers share the host kernel and isolate processes. |
| Image vs container? | Image is the template; container is its running instance. |
| Compose? | Defines and runs the multi-container stack. |
| Dockerfile? | Instructions to build one service image. |
| NGINX? | HTTPS entry point and web server / PHP request forwarding. |
| PHP-FPM? | Runs WordPress PHP code; not the public web server. |
| MariaDB? | Stores WordPress data in database tables. |
| Redis? | In-memory cache used by WordPress. |
| Docker network? | Internal service communication and DNS by service name. |
| Why volumes? | Data survives container recreation. |
| Why two volumes? | Separate database data from website files. |
| `.env` vs secrets? | Configuration values vs confidential values; both stay local in this project. |
| Why 443? | Standard HTTPS port; mandatory NGINX entry point. |
| Why TLS 1.2/1.3? | Required secure protocol versions in the subject. |
| Why `exec`? | Makes the real service process PID 1 so signals are handled properly. |
| Why Glances? | Monitoring and troubleshooting VM resource usage. |

## Final reality check: tested vs still to audit

**Already demonstrated in your VM:** HTTPS and WordPress, TLS 1.2/1.3 tests, MariaDB and WP users, persistence, Redis, FTP login/upload/read/delete, Adminer login, static page, Glances dashboard, reboot recovery.

**Still verify before declaring submission-ready:** clean-clone `make`, exact Dockerfile/Compose/Makefile compliance, no credentials in Git history, docs completeness, base-image versions, the `latest` tag ambiguity, and sufficient VM RAM/disk. This guide does not assert those uninspected source details are correct.
