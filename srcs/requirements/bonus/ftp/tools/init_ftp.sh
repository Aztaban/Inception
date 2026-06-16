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

echo "Creating FTP user: ${FTP_USER}"

if ! id "${FTP_USER}" >/dev/null 2>&1; then
    useradd -m -d /var/www/html -s /usr/sbin/nologin "${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

mkdir -p /var/run/vsftpd/empty
mkdir -p /var/www/html

chown -R "${FTP_USER}:${FTP_USER}" /var/www/html
chmod -R 755 /var/www/html

echo "Starting vsftpd..."

exec /usr/sbin/vsftpd /etc/vsftpd.conf
