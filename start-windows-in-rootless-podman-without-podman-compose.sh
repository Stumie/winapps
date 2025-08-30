#!/usr/bin/env bash

set -e

if [ "$(id -u)" = "0" ]; then
    echo "ERROR! This script must not be run as root!" >&2
    exit 1
fi

check-for-software-existence () {
    for i in $@
    do
    if ! command -v $i &> /dev/null; then
        echo "ERROR: The software package '$i' is necessary but could not be found." >&2; exit 1
    fi
    done
}

install-yq-into-user-directory () {
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ~/.local/bin/yq
    chmod +x ~/.local/bin/yq
}

check-for-software-existence wget podman
install-yq-into-user-directory

readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly CONFIG_PATH="${HOME}/.config/winapps/winapps.conf"

if [ -f "$CONFIG_PATH" ]
then
    readonly COMPOSE_PATH="${HOME}/.config/winapps/compose.yaml"
else
    readonly COMPOSE_PATH="${SCRIPT_DIR_PATH}/compose.yaml"
fi

winlanguage="German"
winregion="de-DE"
winkeyboard="de-DE"

podman volume create --ignore data
podman run \
    -d \
    --name "$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')" \
    --device=/dev/kvm \
    --device=/dev/net/tun \
    --network pasta:-t,127.0.0.1/8006:8006,-t,127.0.0.1/3389:3389,-u,127.0.0.1/3389:3389 \
    -v "data:/storage:z" \
    -v "${HOME}:/shared" \
    -v "$SCRIPT_DIR_PATH/oem:/oem:z" \
    --stop-timeout 120 \
    --uidmap "+0:@$(id -u)" \
    --restart "$(cat $COMPOSE_PATH | yq -r '.services.windows.restart')" \
    -e VERSION="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.VERSION')" \
    -e DISK_SIZE="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.DISK_SIZE')" \
    -e RAM_SIZE="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.RAM_SIZE')" \
    -e CPU_CORES="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.CPU_CORES')" \
    -e USERNAME="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.USERNAME')" \
    -e PASSWORD="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.PASSWORD')" \
    -e HOME="$(cat $COMPOSE_PATH | yq -r '.services.windows.environment.HOME')" \
    -e LANGUAGE="$winlanguage" \
    -e REGION="$winkeyboard" \
    -e KEYBOARD="$winkeyboard" \
    -e NETWORK="user" \
    "$(cat $COMPOSE_PATH | yq -r '.services.windows.image')"
podman ps --all --filter name="$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')"