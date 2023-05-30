#!/bin/bash

set -eo pipefail

if [ -z "${TESLA_BT_MAC}" ]; then
    echo "TESLA_BT_MAC not set"
    exit 1
fi

service rsyslog start
service dbus start
service bluetooth start

sed -i'' "s/AA:BB:CC:DD:EE:FF/${TESLA_BT_MAC}/g" /etc/asound.conf
alsactl init || true

sleep 5

echo "Starting bluealsa"
export LIBASOUND_THREAD_SAFE=0
/usr/bin/bluealsa -p a2dp-source &

echo "Restarting hci0"
hciconfig hci0 down
hciconfig hci0 up
hciconfig noauth

(
    sleep 10
    bluetoothctl scan on
    bluetoothctl discoverable on
    # bluetoothctl trust "${TESLA_BT_MAC}"
    # bluetoothctl pair "${TESLA_BT_MAC}"
    # bluetoothctl connect "${TESLA_BT_MAC}"
) &

echo "Starting index.js"
node index.js