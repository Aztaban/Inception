#!/bin/bash

set -e

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

cd /var/www/html

echo "Waiting for MariaDB...

until mariadb -h mariadb -u"${MYSQL_USER}" -p"{DB_PASSWORD}" "${MYSQL_DATABASE}" -e "SELECT 1;"
    sleep 2;
done

echo "MariaDB is ready"
if [ ! -f "wp-config.php ]; then
    echo "Downloading Wordpress..."

    curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf wordpress.tar.gz --strip-components=1
    rm wordpress.tar.gz

    echo "Creating wp-config.php..."

    cp wp-config-sample.php wp-config.php

    sed -i "s/database_name_here/${MYSQL_DATABASE}/" wp-config.php
	sed -i "s/username_here/${MYSQL_USER}/" wp-config.php
	sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php
	sed -i "s/localhost/mariadb/" wp-config.php

    echo "Installing wp-cli..."

    curl -o https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp

    echo "Installing Wordpress..."

    wp core install \
        --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "Creating normal wordpress user..."

    wp_user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --allow-root \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author

    chown -R www-data:www-data /var/www/html

    echo "Wordpress installation complete."
else
    echo "Wordpress already installed."
fi

echo "Starting php-fpm..."
exec php-fpm8.2 -F