#!/bin/bash

set -eo pipefail

if [ -z "${TESLA_BT_MAC}" ]; then
    echo "TESLA_BT_MAC not set"
    exit 1
fi

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo '*.* -/dev/stdout' > /etc/rsyslog.d/config.conf
cp /etc/asound.conf.default /etc/asound.conf
sed -i'' "s/AA:BB:CC:DD:EE:FF/${TESLA_BT_MAC}/g" /etc/asound.conf

service rsyslog start
service dbus start
service bluetooth start

mkdir -p /etc/udev/rules.d || true
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="1314", ATTRS{idProduct}=="1521", MODE:="0666"' > /etc/udev/rules.d/myrule.rules
service udev restart
udevadm control --reload-rules
service udev restart
udevadm trigger


alsactl init || true

sleep 5

echo "Starting bluealsa"
export LIBASOUND_THREAD_SAFE=0
/usr/bin/bluealsa -p a2dp-source &

echo "Restarting hci0"
hciconfig hci0 down || true
hciconfig hci0 up || true

# (
#     sleep 2
#     bluetoothctl discoverable on
#     # bluetoothctl pairable on
#     bluetoothctl scan on >/dev/null &
#     while ! bluetoothctl trust "${TESLA_BT_MAC}" &>/dev/null; do
#         echo "waiting for ${TESLA_BT_MAC}"
#         sleep 1
#     done
#     bluetoothctl pair "${TESLA_BT_MAC}" || true
#     bluetoothctl connect "${TESLA_BT_MAC}"
#     bluetoothctl scan off
# ) &

if [ -d "/tmp/app" ]; then
    if [ ! -d "/tmp/app/workdir" ]; then
        mkdir /tmp/app/workdir
    fi
    cd /tmp/app/workdir
fi

echo "Starting index.js"
node "../index.js"
