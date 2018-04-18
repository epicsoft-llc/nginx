#/bin/bash

declare -r CUSTOM_DEFAULT_CONF_FILE="/etc/nginx/conf.d/default.conf"

if [[ $NGINX_CUSTOM_ADD_DIRECT_INCLUDE == true ]]; then
  echo "[INFO] $(date -Iseconds) Delete default website configuration file '$CUSTOM_DEFAULT_CONF_FILE'"
  rm -f $CUSTOM_DEFAULT_CONF_FILE
fi