#!/bin/bash

set -e

echo "Starting static website..."

exec nginx -g "daemon off;"