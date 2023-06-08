# syntax=docker/dockerfile:1

FROM debian:bullseye AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked apt-get update && apt-get install -y \
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

RUN --mount=type=cache,target=/root/build cd /root/build && \
    ( test -d bluez-alsa || git clone --depth=1 https://github.com/Arkq/bluez-alsa.git ) && \
    cd bluez-alsa && \
    ( test -d m4 || mkdir -p m4 ) && \
    autoreconf --install &&\
    ( test -d build || mkdir build ) && \
    cd build && \
    ( rm -rf /install/bluez-alsa || true ) && mkdir -p /install/bluez-alsa && \
    ../configure CFLAGS="-g -O0" LDFLAGS="-g" --enable-debug && \
    make && \
    make DESTDIR=/install/bluez-alsa install

FROM node:18-bullseye

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked apt-get update && apt-get install -y \
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
    libspandsp2 \
    alsa-utils \
    rsyslog

COPY --from=build /install/bluez-alsa /
COPY ./conf/asound.conf /etc/asound.conf.default
ENV SDL_AUDIODRIVER=alsa

RUN sed -i'' 's/^ExecStart=.*/\0 --noplugin=sap --plugin=a2dp,avrcp/' /etc/systemd/system/bluetooth.target.wants/bluetooth.service && \
    sed -i'' 's/^#Name = .*/Name = CarPlay/' /etc/bluetooth/main.conf && \
    adduser root bluetooth && \
    adduser root audio

COPY ./package.json /app/package.json
COPY ./package-lock.json /app/package-lock.json
RUN --mount=type=cache,target=/root/.npm cd /app && npm install

COPY ./static /app/static
COPY ./index.js /app/index.js
COPY ./entry.sh /app/entry.sh

WORKDIR /app/workdir
ENTRYPOINT [ "/app/entry.sh" ]
