#!/bin/bash

set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/inception.crt ] || [ ! -f /etc/nginx/ssl/inception.key ]; then
    echo "Generation self-signed SSL certificate..."

    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=CZ/ST=Prague/L=Prague/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

echo "Starting NGINX..."

exec nginx -g "daemon off;"