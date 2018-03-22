#!/bin/sh

ps -a | grep "[n]ginx: master process" > /dev/null || exit 2

if [[ "$(echo "$INOTIFYWAIT_MODIFY_FILES")" != '' && "$(echo "$INOTIFYWAIT_MODIFY_COMMAND")" != '' ]]; then
  ps -a | grep [i]notifywait > /dev/null || exit 3
fi
