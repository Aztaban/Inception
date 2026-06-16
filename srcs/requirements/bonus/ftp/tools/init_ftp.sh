#!/bin/bash

set -e

FTP_PASSWORD="$(cat /run/secrets/ftp_password)"

if [ -z "${FTP_USER}" ]; then
	echo "FTP_USER is not set"
	exit 1
fi

if [ -z "${FTP_PASSWORD}" ]; then
	echo "FTP password is empty"
	exit 1
fi

mkdir -p /var/run/vsftpd/empty
mkdir -p /var/www/html

if ! grep -q "^/usr/sbin/nologin$" /etc/shells; then
	echo "/usr/sbin/nologin" >> /etc/shells
fi

if ! id "${FTP_USER}" >/dev/null 2>&1; then
	echo "Creating FTP user: ${FTP_USER}"
	useradd -M -d /var/www/html -s /usr/sbin/nologin "${FTP_USER}"
else
	echo "FTP user already exists: ${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

chown -R "${FTP_USER}:${FTP_USER}" /var/www/html
chmod -R 755 /var/www/html

echo "Starting vsftpd..."

exec /usr/sbin/vsftpd /etc/vsftpd.conf