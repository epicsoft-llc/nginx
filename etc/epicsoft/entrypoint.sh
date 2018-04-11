#!/bin/bash

set -e

#### Start observer as a background process
/bin/bash /etc/epicsoft/observer.sh &

exec "$@"