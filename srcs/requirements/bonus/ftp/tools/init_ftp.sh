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

# Make sure nologin is accepted as a valid shell for FTP users
if ! grep -q "^/usr/sbin/nologin$" /etc/shells; then
	echo "/usr/sbin/nologin" >> /etc/shells
fi

# Make sure www-data group exists
if ! getent group www-data >/dev/null 2>&1; then
	groupadd www-data
fi

# Create FTP user if it does not exist
if ! id "${FTP_USER}" >/dev/null 2>&1; then
	echo "Creating FTP user: ${FTP_USER}"
	useradd -M -d /var/www/html -s /usr/sbin/nologin -g www-data "${FTP_USER}"
else
	echo "FTP user already exists: ${FTP_USER}"
	usermod -aG www-data "${FTP_USER}"
fi

# Set FTP user password from Docker secret
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

# Make WordPress volume writable by www-data group
chown -R www-data:www-data /var/www/html

# Directories:
# 2 = setgid bit, so new files/directories inherit www-data group
# 775 = owner and group can write
find /var/www/html -type d -exec chmod 2775 {} \;

# Files:
# 664 = owner and group can write
find /var/www/html -type f -exec chmod 664 {} \;

echo "Starting vsftpd..."

exec /usr/sbin/vsftpd /etc/vsftpd.conf