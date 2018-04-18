#!/bin/bash

declare -r CUSTOM_NGINX_CONFIG_FILE="/etc/nginx/nginx.conf"
declare -r CUSTOM_NGINX_LOG_FILE="/var/log/nginx/access.log"

if [[ $NGINX_CUSTOM_LOGFORMAT_ENABLE == true ]]; then 
  echo "[INFO] $(date -Iseconds) Custom log format enabled"
  declare -r CUSTOM_NGINX_LOG_FORMAT="log_format $NGINX_CUSTOM_LOGFORMAT_NAME '$NGINX_CUSTOM_LOGFORMAT';"

  if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
    echo "[DEBUG] $(date -Iseconds) Use custom log format name: $NGINX_CUSTOM_LOGFORMAT_NAME"
    echo "[DEBUG] $(date -Iseconds) Use custom log format: $CUSTOM_NGINX_LOG_FORMAT"
  fi

  sed -i.bak -e "s#access_log\s\{1,\}$CUSTOM_NGINX_LOG_FILE\s\{1,\}main\s\{0,\};#$CUSTOM_NGINX_LOG_FORMAT\n\n    access_log $CUSTOM_NGINX_LOG_FILE $NGINX_CUSTOM_LOGFORMAT_NAME;#g" $CUSTOM_NGINX_CONFIG_FILE
fi
