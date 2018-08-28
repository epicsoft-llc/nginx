#!/bin/bash

set -e

declare -r CUSTOM_NGINX_CONFIG_FILE="/etc/nginx/nginx.conf"

#### Default configration 
bash /etc/epicsoft/default_conf.sh

#### Update http config 
bash /etc/epicsoft/http_config.sh

#### Add additional include directory
bash /etc/epicsoft/direct_include.sh

#### Custom Log format
bash /etc/epicsoft/logformat.sh

#### Print main nginx configration file
if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
  echo "[DEBUG] $(date -Iseconds) Print nginx configuration file: $CUSTOM_NGINX_CONFIG_FILE"
  cat $CUSTOM_NGINX_CONFIG_FILE
fi

#### Start observer as a background process
bash /etc/epicsoft/observer.sh &

exec "$@"