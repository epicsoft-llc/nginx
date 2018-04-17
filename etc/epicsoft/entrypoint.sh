#!/bin/bash

set -e

#### Custom Log format
bash /etc/epicsoft/logformat.sh

#### Start observer as a background process
bash /etc/epicsoft/observer.sh &

exec "$@"