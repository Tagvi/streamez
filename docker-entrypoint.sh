#!/usr/bin/env sh
set -eu

envsubst '${NAME_SERVER} ${AUTH_SERVER}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec "$@"
