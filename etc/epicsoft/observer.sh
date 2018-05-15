#!/bin/bash

declare -r CHECKSUM_FILE="/tmp/epicsoft_observer.checksum"
declare CHECKSUM_FILES_COUNT=-1

function readChecksum(){
  if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
    echo "[DEBUG] $(date -Iseconds) Create checksum file and count files"
  fi

  $(sha512sum $OBSERVE_FILES 2>/dev/null > $CHECKSUM_FILE)
  CHECKSUM_FILES_COUNT=$(ls -l $OBSERVE_FILES 2>/dev/null | wc -l)

  if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
    echo "[DEBUG] $(date -Iseconds) Found '$CHECKSUM_FILES_COUNT' files with checksum:"
    cat $CHECKSUM_FILE
  fi
}

function excecuteObserverCommand(){
  echo "[INFO] $(date -Iseconds) Change on observing file detected"
  echo "[INFO] $(date -Iseconds) Execute command '$OBSERVE_COMMAND'"
  if $(bash -c "$OBSERVE_COMMAND"); then
    #### OK: excecute command without errors
    :
  fi
}

if [[ $OBSERVE_FILES_ENABLE == true && "$(echo "$OBSERVE_FILES")" != '' && "$(echo "$OBSERVE_COMMAND")" != '' ]]; then
  if [[ $OBSERVE_FILES_CREATE == true ]]; then   
    for FILE in $OBSERVE_FILES ; do      
      if [[ ! -f $FILE && ! -d $FILE ]]; then
        mkdir -p "$(dirname $FILE)"
        if [[ $FILE != *"*"* ]]; then 
          echo "[INFO] $(date -Iseconds) File '$FILE' not found, it will be created."
          touch $FILE
        else
          echo "[WARN] $(date -Iseconds) Files with wildcard would not be created '$FILE'"
        fi 
      fi
    done
  fi
  
  readChecksum
  echo "[INFO] $(date -Iseconds) Starting observation for files '$OBSERVE_FILES' with command '$OBSERVE_COMMAND'"
  while true; do
    if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
      echo "[DEBUG] $(date -Iseconds) Observer started ..."
    fi
    
    if [[ $(ls -l $OBSERVE_FILES 2>/dev/null | wc -l) == $CHECKSUM_FILES_COUNT ]]; then
      if $(sha512sum -csw $CHECKSUM_FILE); then
        #### OK: No change found
        :
      else
        if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
          echo "[DEBUG] $(date -Iseconds) Checksum change detect"
        fi
        excecuteObserverCommand
        readChecksum
      fi
    else
      if [[ $EPICSOFT_LOG_LEVEL_DEBUG == true ]]; then
        echo "[DEBUG] $(date -Iseconds) File count change detect"
      fi
      excecuteObserverCommand
      readChecksum
    fi

    sleep $OBSERVE_INTERVAL
  done
fi
