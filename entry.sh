#!/bin/bash

set -eo pipefail


service dbus start
service bluetooth start
export LIBASOUND_THREAD_SAFE=0
/usr/local/bin/bluealsa -S &

hciconfig hci0 down
hciconfig hci0 up

node index.js