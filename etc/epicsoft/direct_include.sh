#/bin/bash

declare -r CUSTOM_NGINX_CONFIG_FILE="/etc/nginx/nginx.conf"
declare -r CUSTOM_INCLUDE_DIR="/etc/nginx/inc.d"
declare -r CUSTOM_INCLUDE_COMMAND="include $CUSTOM_INCLUDE_DIR/*.conf;"

if [[ $NGINX_CUSTOM_ADD_DIRECT_INCLUDE == true ]]; then
  mkdir -p $CUSTOM_INCLUDE_DIR

  _IN_FILE=$(cat $CUSTOM_NGINX_CONFIG_FILE | grep -c "$CUSTOM_INCLUDE_DIR")
  if [ $_IN_FILE -eq 0 ]; then
    echo "[INFO] $(date -Iseconds) Add additional include directory to nginx configuration '$CUSTOM_INCLUDE_DIR'"
    echo -e "\n"$CUSTOM_INCLUDE_COMMAND"\n" >> $CUSTOM_NGINX_CONFIG_FILE
  fi
fi
