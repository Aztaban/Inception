#!/bin/bash

set -e

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

cd /var/www/html

echo "Waiting for MariaDB..."

until mariadb -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" "${MYSQL_DATABASE}" -e "SELECT 1;" --silent 2>/dev/null; do
	sleep 2
done

echo "MariaDB is ready"

if [ ! -f "wp-config.php" ]; then
	echo "Downloading WordPress..."

	curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
	tar -xzf wordpress.tar.gz --strip-components=1
	rm wordpress.tar.gz

	echo "Creating wp-config.php..."

	cp wp-config-sample.php wp-config.php

	sed -i "s/database_name_here/${MYSQL_DATABASE}/" wp-config.php
	sed -i "s/username_here/${MYSQL_USER}/" wp-config.php
	sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php
	sed -i "s/localhost/mariadb/" wp-config.php

	echo "Installing WordPress..."

	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="https://${DOMAIN_NAME}" \
		--title="Inception" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}"

	echo "Creating normal WordPress user..."

	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--allow-root \
		--path=/var/www/html \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=author

	echo "WordPress installation complete."
else
	echo "WordPress already installed."
fi

echo "Configuring Redis cache..."

wp config set WP_REDIS_HOST redis \
	--type=constant \
	--allow-root \
	--path=/var/www/html

wp config set WP_REDIS_PORT 6379 \
	--type=constant \
	--raw \
	--allow-root \
	--path=/var/www/html

wp config set WP_CACHE true \
	--type=constant \
	--raw \
	--allow-root \
	--path=/var/www/html

echo "Installing/enabling Redis Object Cache plugin..."

if ! wp plugin is-installed redis-cache --allow-root --path=/var/www/html; then
	wp plugin install redis-cache \
		--activate \
		--allow-root \
		--path=/var/www/html
else
	wp plugin activate redis-cache \
		--allow-root \
		--path=/var/www/html
fi

echo "Enabling Redis object cache..."

wp redis enable --allow-root --path=/var/www/html || true

chown -R www-data:www-data /var/www/html

echo "Redis status:"
wp redis status --allow-root --path=/var/www/html || true

echo "Starting php-fpm..."

exec php-fpm8.2 -F