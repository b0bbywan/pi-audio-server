#!/bin/bash

ACTION=$1
DEVICE=$2
MPDPORT=6600
MPC="mpc --port=${MPDPORT}"

if [[ -z ${ACTION} ]]; then
    logger "error: No ACTION specified"
    exit 1
fi

MOUNT_POINT=$(mount | grep ${DEVICE} | awk '{ print $3 }')
LABEL=$(basename ${MOUNT_POINT})

do_mount() {
    logger "info: updating mpd database..."
    ${MPC} update --wait
    logger "info: clearing previous queue"
    ${MPC} clear
    logger "info: adding ${LABEL} files to queue"
    ${MPC} add ${LABEL}
    logger "info: playing queue"
    ${MPC} play
}

do_unmount() {
    ${MPC} stop
    logger "info: clearing previous queue from ${LABEL} files"
    ${MPC} --format="%position% %file%" playlist | grep ${LABEL} | awk '{ print $1 }' | ${MPC} del
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
