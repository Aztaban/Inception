#!/bin/bash

set -e

LOGIN="mjusta"
DOMAIN_NAME="${LOGIN}.42.fr"

echo "Updating packages..."
sudo apt update

echo "Installing dependencies..."
sudo apt install -y \
  make \
  git \
  curl \
  vim \
  docker.io \
  docker-compose

echo "Creating data directories..."
sudo mkdir -p /home/${LOGIN}/data/mariadb
sudo mkdir -p /home/${LOGIN}/data/wordpress
sudo chown -R "$USER:$USER" /home/${LOGIN}/data

echo "Adding user to docker group..."
sudo usermod -aG docker "$USER"

echo "Adding local domain to /etc/hosts..."
if ! grep -q "${DOMAIN_NAME}" /etc/hosts; then
  echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts
fi

echo "VM setup done."
echo "You may need to log out/reboot for Docker group changes to apply."