#!/bin/bash

set -e

/bin/bash /etc/epicsoft/observer.sh &

exec "$@"