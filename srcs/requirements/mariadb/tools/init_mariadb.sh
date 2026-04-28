#!/bin/bash

set -e

DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing MariaDB data directory..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db

	echo "Starting temporary MariaDB server..."
	mysqld_safe --datadir=/var/lib/mysql --skip-networking &
	MYSQLD_PID="$!"

	until mariadb-admin ping --silent; do
		sleep 1
	done

	echo "Configuring database and users..."

	mariadb -u root <<-EOSQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL

	echo "Stopping temporary MariaDB server..."
	mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown

	wait "$MYSQLD_PID" || true

	echo "MariaDB initialization complete."
else
	echo "MariaDB data directory already initialized."
fi

echo "Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql