#!/bin/sh
#### The last step before nginx starts: the watcher's baseline is the configuration nginx is about to load

if [ -n "${NGINX_WATCH}" ]; then
  nginx-watch < /dev/null &
fi
