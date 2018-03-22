#!/bin/sh

set -e

if [[ "$(echo "$INOTIFYWAIT_MODIFY_FILES")" != '' && "$(echo "$INOTIFYWAIT_MODIFY_COMMAND")" != '' ]]; then
  if [[ $INOTIFYWAIT_MODIFY_FILES_CREATE ]]; then   
    for FILE in $INOTIFYWAIT_MODIFY_FILES ; do
      if [[ ! -f $FILE && ! -d $FILE ]]; then
        echo "[INFO] File '$FILE' not found, it will be created."
        touch $FILE
      fi
    done
  fi
  
  echo "[INFO] Starting 'inotifywait' for files '$INOTIFYWAIT_MODIFY_FILES' with command '$INOTIFYWAIT_MODIFY_COMMAND'"
  while inotifywait -q -e modify $INOTIFYWAIT_MODIFY_FILES; do 
    echo "[INFO] Execute command '$INOTIFYWAIT_MODIFY_COMMAND'"
    eval "$INOTIFYWAIT_MODIFY_COMMAND"
  done &
fi

exec "$@"
