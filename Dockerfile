#### https://hub.docker.com/_/nginx
ARG NGINX_TAG=alpine
FROM nginx:${NGINX_TAG}

ARG IMAGE_TAG="local"
ARG BUILD_DATE="development"
#### NGINX_VERSION is set by the official image
LABEL org.label-schema.name="nginx" \
      org.label-schema.description="Official nginx image with automatic graceful reload on config change and a reload-aware healthcheck" \
      org.label-schema.vendor="epicsoft LLC / Alexander Schwarz <info@epicsoft.one>" \
      org.label-schema.url="https://gitlab.com/epicsoft-networks/nginx" \
      org.label-schema.vcs-url="https://gitlab.com/epicsoft-networks/nginx/-/tree/master" \
      org.label-schema.version=${IMAGE_TAG} \
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=${BUILD_DATE}

LABEL image.name="epicsoft_nginx" \
      image.description="Official nginx image with automatic graceful reload on config change and a reload-aware healthcheck" \
      image.nginx.version=${NGINX_VERSION} \
      maintainer="epicsoft LLC" \
      maintainer.name="Alexander Schwarz <info@epicsoft.one>" \
      maintainer.copyright="Copyright 2018-2026 epicsoft LLC / Alexander Schwarz" \
      license="MIT"

#### packages of the base image lag behind the Alpine repository - the upgrade brings their security fixes
RUN apk --no-cache upgrade \
 && apk --no-cache add inotify-tools

COPY --chmod=755 rootfs/usr/local/bin/ /usr/local/bin/
COPY --chmod=755 rootfs/docker-entrypoint.d/ /docker-entrypoint.d/

ENV NGINX_WATCH="/etc/nginx" \
    NGINX_WATCH_INTERVAL="5" \
    NGINX_CONTROL_SOCKET="/var/run/nginx-control.sock" \
    NGINX_RELOAD_WEBHOOK_SUCCESS_URL="" \
    NGINX_RELOAD_WEBHOOK_FAILURE_URL=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=1 CMD [ "nginx-healthcheck" ]

ENTRYPOINT [ "nginx-entrypoint" ]

#### an own ENTRYPOINT drops the CMD of the base image - this is the official one
CMD [ "nginx", "-g", "daemon off;" ]
