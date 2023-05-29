FROM node:18-bullseye

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    libdbus-1-dev \
    libudev-dev \
    ffmpeg \
    dbus \
    bluez \
    bluez-tools \
    git \
    libglib2.0-dev \
    libasound2-dev \
    libbluetooth-dev \
    libtool \
    libsbc-dev \
    libspandsp-dev

RUN cd /root && \
    git clone https://github.com/Arkq/bluez-alsa.git && \
    cd bluez-alsa && \
    mkdir -p m4 && \
    autoreconf --install &&\
    mkdir build && \
    cd build && \
    ../configure CFLAGS="-g -O0" LDFLAGS="-g" --enable-debug && \
    make && \
    make install && \
    adduser root bluetooth && \
    adduser root audio && \
    cd /root && \
    rm -rf bluez-alsa

RUN sed -i'' 's/^ExecStart=.*/\0 --noplugin=sap --plugin=a2dp,avrcp/' /etc/systemd/system/bluetooth.target.wants/bluetooth.service && \
    sed -i'' 's/^#Name = .*/Name = CarPlay/' /etc/bluetooth/main.conf

COPY . /app
WORKDIR /app

RUN npm install
ENTRYPOINT [ "./entry.sh" ]
