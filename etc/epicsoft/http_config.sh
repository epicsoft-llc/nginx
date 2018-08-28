#!/bin/bash

declare -r CUSTOM_NGINX_CONFIG_FILE="/etc/nginx/nginx.conf"
declare -r CUSTOM_SERVER_TOKENS_OFF="server_tokens off;"

if [[ $NGINX_CUSTOM_ADD_SERVER_TOKENS_OFF == true ]]; then
  echo "[INFO] $(date -Iseconds) Add '$CUSTOM_SERVER_TOKENS_OFF' to nginx configuration"
  sed -i.bak -e "s/http\s\{1,\}{/http {\n    $CUSTOM_SERVER_TOKENS_OFF\n/g" $CUSTOM_NGINX_CONFIG_FILE
fi

if [[ "$(echo "$NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE")" != '' ]]; then 
  echo "[INFO] $(date -Iseconds) Add 'server_names_hash_bucket_size $NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE;' to nginx configuration"
  sed -i.bak -e "s/http\s\{1,\}{/http {\n    server_names_hash_bucket_size $NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE;\n/g" $CUSTOM_NGINX_CONFIG_FILE
fi