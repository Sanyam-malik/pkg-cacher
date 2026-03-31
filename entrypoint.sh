#!/bin/sh
set -e

echo "Starting CI Package Cache"

# Defaults
: "${CACHE_SIZE:=10g}"
: "${CACHE_TTL:=24h}"
: "${CACHE_PATH:=/var/cache/nginx}"

export CACHE_SIZE CACHE_TTL CACHE_PATH

echo "Using CACHE_SIZE=$CACHE_SIZE"
echo "Using CACHE_TTL=$CACHE_TTL"
echo "Using CACHE_PATH=$CACHE_PATH"

rm -rf /etc/nginx/conf.d/* /etc/nginx/nginx.conf

envsubst '${CACHE_SIZE} ${CACHE_TTL} ${CACHE_PATH}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/nginx.conf

for template in /etc/nginx/templates/*.template; do
  name=$(basename "$template" .template)

  echo "Generating $name"

  envsubst '${CACHE_SIZE} ${CACHE_TTL} ${CACHE_PATH}' \
    < "$template" \
    > "/etc/nginx/conf.d/$name"
done

nginx -t

exec nginx -g 'daemon off;'