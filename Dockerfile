ARG VERSION=alpine
FROM nginx:$VERSION
LABEL image.name="nginx" \
      image.description="Nginx with inotifywait and automatic reload on file change" \
      maintainer="epicsoft.de" \
      maintainer.name="Alexander Schwarz <schwarz@epicsoft.de>" \
      maintainer.copyright="Copyright 2018 epicsoft.de / Alexander Schwarz" \
      license="MIT"

ENV INOTIFYWAIT_MODIFY_FILES="" \
    INOTIFYWAIT_MODIFY_FILES_CREATE=true \
    INOTIFYWAIT_MODIFY_COMMAND="nginx -s reload"

COPY [ "etc/", "etc/"]

RUN apk --no-cache add inotify-tools \
 && chmod +x /etc/epicsoft/*.sh

ENTRYPOINT [ "/etc/epicsoft/entrypoint.sh" ]

HEALTHCHECK CMD [ "/etc/epicsoft/healthcheck.sh" ]

#### CMD copied from base image
CMD ["nginx", "-g", "daemon off;"]
