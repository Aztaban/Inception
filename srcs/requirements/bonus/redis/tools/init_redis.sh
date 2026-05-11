#!bin/sh

set -e

echo "Starting Redis cache server..."

exec redis-server /etc/redis/redis.conf