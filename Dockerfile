ARG VERSION=alpine
FROM nginx:$VERSION
LABEL image.name="epicsoft-nginx" \
      image.description="Nginx with automatic reload on file/configuration change" \
      maintainer="epicsoft.de" \
      maintainer.name="Alexander Schwarz <schwarz@epicsoft.de>" \
      maintainer.copyright="Copyright 2018 epicsoft.de / Alexander Schwarz" \
      license="MIT"

ENV OBSERVE_FILES="/etc/nginx/conf.d/default.conf" \
    OBSERVE_FILES_CREATE=true \
    OBSERVE_COMMAND="nginx -s reload" \
    OBSERVE_INTERVAL=10

COPY [ "etc/", "etc/"]

RUN apk --no-cache add bash \
 && chmod +x /etc/epicsoft/*.sh

ENTRYPOINT [ "/etc/epicsoft/entrypoint.sh" ]

HEALTHCHECK CMD [ "/etc/epicsoft/healthcheck.sh" ]

#### CMD copied from base image
CMD ["nginx", "-g", "daemon off;"]
