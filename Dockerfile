FROM debian:bullseye AS build

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    git \
    libdbus-1-dev \
    libudev-dev \
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
    mkdir -p /install/bluez-alsa && \
    ../configure CFLAGS="-g -O0" LDFLAGS="-g" --enable-debug --prefix=/install/bluez-alsa && \
    make && \
    make install

FROM node:18-bullseye

RUN apt-get update && apt-get install -y \
    ffmpeg \
    dbus \
    bluez \
    bluez-tools \
    libdbus-1-dev \
    libudev-dev \
    libglib2.0-0 \
    libasound2 \
    libbluetooth3 \
    libsbc1 \
    libspandsp2

COPY --from=build /install/bluez-alsa /usr/local

RUN sed -i'' 's/^ExecStart=.*/\0 --noplugin=sap --plugin=a2dp,avrcp/' /etc/systemd/system/bluetooth.target.wants/bluetooth.service && \
    sed -i'' 's/^#Name = .*/Name = CarPlay/' /etc/bluetooth/main.conf && \
    adduser root bluetooth && \
    adduser root audio

COPY . /app
WORKDIR /app

RUN npm install
ENTRYPOINT [ "./entry.sh" ]
