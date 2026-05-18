#!/bin/bash

set -e

echo "Starting Glances web monitor..."

exec glances -w --bind 0.0.0.0 --port 61208