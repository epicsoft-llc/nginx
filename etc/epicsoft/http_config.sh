#!/bin/bash

declare -r CUSTOM_NGINX_CONFIG_FILE="/etc/nginx/nginx.conf"
declare -r CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE="/etc/nginx/nginx.additional.conf"

#### Clean content of additional nginx configuration file 
echo '' > $CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE

if [[ $NGINX_CUSTOM_ADD_SERVER_TOKENS_OFF == true ]]; then
  echo "[INFO] $(date -Iseconds) Add 'server_tokens off;' to nginx '$CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE' configuration"
  echo -e "server_tokens off;" >> $CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE
fi

if [[ $NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE != '' ]]; then 
  echo "[INFO] $(date -Iseconds) Add 'proxy_headers_hash_bucket_size $NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE;' to nginx '$CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE' configuration"
  echo -e "proxy_headers_hash_bucket_size $NGINX_CUSTOM_PROXY_HEADERS_HASH_BUCKET_SIZE;" >> $CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE
fi

if [[ $(grep "$CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE" $CUSTOM_NGINX_CONFIG_FILE | wc -l) == 0 ]]; then
  echo "[INFO] $(date -Iseconds) Add 'include $CUSTOM_ADDITIONAL_NGINX_CONFIG_FILE;' to nginx '$CUSTOM_NGINX_CONFIG_FILE' configuration"
  sed -i.bak -e "s/http\s\{1,\}{/http {\n    include \/etc\/nginx\/nginx.additional.conf;\n/g" $CUSTOM_NGINX_CONFIG_FILE
fi
