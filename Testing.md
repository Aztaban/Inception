# Testing services

## Nginx

```bash
curl -kI https://localhost
```

Expected:

```
HTTP/1.1 200 OK
```

Also test domain.

```bash
curl -kI https://mjusta.42.fr
```

## Wordpress container

```bash
docker exec -it wordpress php -v
```

Expected: PHP version output

Check WordPress files:

```bash
docker exec -it wordpress ls -la /var/www/html
```

You should see files like:

```
wp-config.php
wp-content
wp-admin
wp-includes
```

## MariaDB

```bash
docker exec -it mariadb mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
```

if env variables are not available from your shell, use the actual values manually.

Inside MariaDB:

```SQL
SHOW TABLES;
```

Expected WordPress tables:

```
wp_users
wp_posts
wp_options
...
```

Exit:

```SQL:
exit;
```

## Volumes persistence test

Create or edit something in WordPress, then:

```bash
docker compose down
docker compose up -d
```

Open WordPress again.

Your site/data should still exist.

Do not use this unless you want to erase data:

```bash
docker compose down -v
```

## Redis

```bash
docker exec -it redis redis-cli ping
```

Expected

```
PONG
```

Check PHP Redis extension inside WordPress:

```bash
docker exec -it wordpress php -m | grep -i redis
```

Expected:

```
redis
```

Test Wordpress can reach Redis:

```bash
docker exec -it wordpress php -r '$r = new Redis(); $r->connect("redis", 6379); echo $r->ping() . PHP_EOL;'
```

Expected:

```
1
or
+PONG
```

After browsing your WordPress site, check if Redis has keys:

```bash
docker exec -it redis redis-cli --scan | head
```

If it prints keys, Redis is actually being used.


## Adminer

```bash
curl -I http://localhost:8080
```

Expected:

```
HTTP/1.1 200 OK
```

Then open in browser:

```
http://localhost:8080
```

Login values should be:

```
System: MySQL / MariaDB
Server: mariadb
Username: MYSQL_USER
Password: MYSQL_PASSWORD
Database: MYSQL_DATABASE
```

## Static site

```bash
curl -I http://localhost:8081
```

Expected:

```
HTTP/1.1 200 OK
```

Then browser

```
http://localhost:8081
```

## FTP

Check port:

```bash
ss -tulpn | grep ':21'
```

Them test with lftp:

```bash
lftp -u mjusta,YOUR_FTP_PASSWORD ftp://127.0.0.1
```

inside lftp:

```bash
ls
put /etc/hostname -o ftp-test.txt
ls
bye
```

Then verify from WordPress:

```bash
docker exec -it wordpress find /var/www/html -name "ftp-test.txt"
```

Expected:

```
/var/www/html/ftp-test.txt
```

## Glances

```bash
curl -I http://localhost:61208
```

Expected:

```
HTTP/1.1 200 OK
```

Open in browser

```
http://localhost:61208
```

You should see glances web UI.