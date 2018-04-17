#!/bin/bash

declare -r CHECKSUM_COMMAND="sha512sum"
declare -r CHECKSUM_COMMAND_ARGS="-csw"
declare -a CHECKSUM_OBSERVE_FILES

function readChecksum(){
  CHECKSUM_OBSERVE_FILES=()
  for FILE in $OBSERVE_FILES ; do
    CHECKSUM_OBSERVE_FILES+=("$($CHECKSUM_COMMAND $FILE)")
  done
}

if [[ "$(echo "$OBSERVE_FILES")" != '' && "$(echo "$OBSERVE_COMMAND")" != '' ]]; then
  if [[ $OBSERVE_FILES_CREATE == true ]]; then   
    for FILE in $OBSERVE_FILES ; do
      if [[ ! -f $FILE && ! -d $FILE ]]; then
        echo "[INFO] $(date -Iseconds) File '$FILE' not found, it will be created."
        touch $FILE
      fi
    done
  fi
  
  readChecksum
  echo "[INFO] $(date -Iseconds) Starting observation for files '$OBSERVE_FILES' with command '$OBSERVE_COMMAND'"  
  while true; do
    for CHECKSUM in "${CHECKSUM_OBSERVE_FILES[@]}" ; do
      if echo "$CHECKSUM" | $CHECKSUM_COMMAND $CHECKSUM_COMMAND_ARGS; then        
        #### OK: No change found
        :
      else
        echo "[INFO] $(date -Iseconds) File changed '$(echo $CHECKSUM | awk '{print $2}')'"
        echo "[INFO] $(date -Iseconds) Execute command '$OBSERVE_COMMAND'"
        if $(echo $OBSERVE_COMMAND); then
          #### OK: excecure command without errors
          :
        fi
        readChecksum
        break
      fi
    done
   
    sleep $OBSERVE_INTERVAL
  done
fi