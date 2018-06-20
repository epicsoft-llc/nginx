ARG VERSION=alpine
FROM nginx:$VERSION
LABEL image.name="epicsoft-nginx" \
      image.description="Nginx with automatic reload on file/configuration change" \
      maintainer="epicsoft.de" \
      maintainer.name="Alexander Schwarz <schwarz@epicsoft.de>" \
      maintainer.copyright="Copyright 2018 epicsoft.de / Alexander Schwarz" \
      license="MIT"

ENV OBSERVE_FILES_ENABLE=true \
    OBSERVE_FILES="/etc/nginx/conf.d/*.conf" \
    OBSERVE_FILES_CREATE=true \
    OBSERVE_COMMAND="nginx -t && nginx -s reload" \
    OBSERVE_INTERVAL=10 \
    NGINX_CUSTOM_LOGFORMAT_ENABLE=false \    
    NGINX_CUSTOM_LOGFORMAT='Custom log format - $remote_addr - $remote_user [$time_local] "$request"' \    
    NGINX_CUSTOM_LOGFORMAT_NAME="custom" \
    NGINX_CUSTOM_ADD_SERVER_TOKENS_OFF=false \
    NGINX_CUSTOM_ADD_DIRECT_INCLUDE=false \
    NGINX_CUSTOM_DELETE_DEFAULT_CONF=false \
    EPICSOFT_LOG_LEVEL_DEBUG=false

RUN apk --no-cache add bash \
 && rm -rf /var/cache/apk/*

COPY [ "etc/", "etc/"]

RUN chmod +x /etc/epicsoft/*.sh

ENTRYPOINT [ "/etc/epicsoft/entrypoint.sh" ]

HEALTHCHECK CMD [ "/etc/epicsoft/healthcheck.sh" ]

#### CMD copied from base image
CMD ["nginx", "-g", "daemon off;"]
