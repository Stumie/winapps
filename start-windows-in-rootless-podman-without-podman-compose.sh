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
        echo "ERROR: The software package '$i' is necessary but could not be found." >&2
        exit 1
    fi
    done
}

install-yq-into-user-directory () {
    curl -s -L -z ~/.local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o ~/.local/bin/yq
    chmod +x ~/.local/bin/yq
}

check-for-software-existence curl podman
install-yq-into-user-directory

readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly CONFIG_PATH="${HOME}/.config/winapps/winapps.conf"

if [ -f "${HOME}/.config/winapps/compose.yaml" ]; then
    readonly COMPOSE_PATH="${HOME}/.config/winapps/compose.yaml"
else
    readonly COMPOSE_PATH="${SCRIPT_DIR_PATH}/compose.yaml"
fi

CONTAINER_STATE=""

CONTAINER_STATE=$(podman ps --all --filter name="$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')" --format '{{.Status}}')
CONTAINER_STATE=${CONTAINER_STATE,,}
CONTAINER_STATE=${CONTAINER_STATE%% *}

if [[ "$CONTAINER_STATE" != "up" ]]; then
    if [[ "$(podman ps --all --filter name="$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')" --format '{{.Names}}')" != "$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')" ]]; then
        winregion="${LANG%.*}"
        winkeyboard="${LANG%.*}"

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
            -e REGION="${winregion//_/-}" \
            -e KEYBOARD="${winkeyboard//_/-}" \
            -e NETWORK="user" \
            "$(cat $COMPOSE_PATH | yq -r '.services.windows.image')"
    else
        podman restart "$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')"
    fi
fi
podman ps --all --filter name="$(cat $COMPOSE_PATH | yq -r '.services.windows.container_name')"