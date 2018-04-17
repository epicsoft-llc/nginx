#!/bin/sh

ps -a | grep "[n]ginx: master process" > /dev/null || exit 2

ps -a | grep "[n]ginx: worker process" > /dev/null || exit 3

if [[ "$(echo "$OBSERVE_FILES")" != '' && "$(echo "$OBSERVE_COMMAND")" != '' ]]; then
  ps -a | grep "[b]ash /etc/epicsoft/observer.sh" > /dev/null || exit 4
fi
