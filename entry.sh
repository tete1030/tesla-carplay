#!/bin/bash

set -eo pipefail


service dbus start
service bluetooth start
export LIBASOUND_THREAD_SAFE=0
/bin/bluealsa -p a2dp-source &

hciconfig hci0 down
hciconfig hci0 up

node index.js