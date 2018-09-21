#!/bin/sh
set -e

sudo service postgresql restart
sudo -u postgres createuser --superuser -e root
sudo -u postgres createuser --superuser -e travis

exec "$@"
