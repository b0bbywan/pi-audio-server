#!/bin/bash

ACTION="$1"
DEV="/dev/cdrom"
MPC="/usr/bin/mpc --host=/run/user/1000/mpd/socket"
ENV_FILE="/tmp/cd_var.env"

# Check if ACTION is provided
if [[ -z ${ACTION} ]]; then
    logger "error: No ACTION specified"
    exit 1
fi

cdda_load() {
    local num_tracks
    num_tracks=$(udevadm info --query=property "${DEV}" | grep ID_CDROM_MEDIA_TRACK_COUNT_AUDIO | awk -F= '{ print $2 }')
    if [[ -z ${num_tracks} ]]; then
        logger "warning: Failed to detect CD tracks, adding whole cd"
        ${MPC} add "cdda://"
        return 1
    fi

    logger "info: CD with ${num_tracks} tracks detected"
    for i in $(seq 1 "${num_tracks}"); do
        ${MPC} add "cdda:///${i}"
    done
}

cue_load() {
    if [[ ! -f ${ENV_FILE} ]]; then
        logger "warning: ${ENV_FILE} not found"
        return 1
    fi

    source "${ENV_FILE}"
    if [[ -z ${CUE_FILE} || ! -s ${CUE_FILE} ]]; then
        logger "warning: Playlist empty or undefined"
        return 1
    fi
    logger "info: Loading playlist from ${CUE_FILE}"
    ${MPC} load "${CUE_FILE}"
}

do_mount() {
    logger "info: Clearing mpd queue"
    ${MPC} clear

    if ! cue_load; then
        logger "info: Falling back to basic cdda"
        cdda_load
    fi

    ${MPC} play
}

do_unmount() {
    ${MPC} stop
    logger "info: Clearing mpd queue before exit"
    ${MPC} --format="%position% %file%" playlist | grep 'cdda://' | awk '{ print $1 }' | ${MPC} del
    rm --force "${ENV_FILE}"
}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    *)
        logger "error: Invalid ACTION '${ACTION}'"
        exit 1
        ;;
esac
