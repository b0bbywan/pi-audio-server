#!/bin/bash

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"

if [[ -z ${ACTION} ]]; then
    logger "error: No ACTION specified"
    exit 1
fi

# See if this drive is already mounted
MOUNT_POINT=$(mount | grep ${DEVICE} | awk '{ print $3 }')
BASE_MOUNT_POINT="/media/USB"


do_mount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        # Already mounted, exit
        exit 0
    fi

    # Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
    eval $(blkid --output udev ${DEVICE})

    # Figure out a mount point to use
    LABEL=${ID_FS_LABEL}
    if [[ -z "${LABEL}" ]]; then
        LABEL=${DEVBASE}
    elif grep --quiet " ${BASE_MOUNT_POINT}/${LABEL} " /etc/mtab; then
        # Already in use, make a unique one
        LABEL+="-${DEVBASE}"
    fi
    MOUNT_POINT="${BASE_MOUNT_POINT}/${LABEL}"

    mkdir --parents ${MOUNT_POINT}

    # Global mount options
    OPTS="rw,relatime,uid=1000,gid=29,umask=0022"

    # File system type specific mount options
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",users,shortname=mixed,utf8=1,flush"
    fi

    if ! mount --options ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        # Error during mount process: cleanup mountpoint
        rmdir ${MOUNT_POINT}
        exit 1
    fi
    logger "info: ${MOUNT_POINT} mounted"
}

do_unmount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        umount --lazy ${DEVICE}
    fi

    # Delete all empty dirs in /media that aren't being used as mount points.
    for f in ${BASE_MOUNT_POINT}/* ; do
        if [[ -n $(find "$f" -maxdepth 0 -type d -empty) ]]; then
            if ! grep --quiet " $f " /etc/mtab; then
                rmdir "$f"
            fi
        fi
    done
    logger "info: ${MOUNT_POINT} unmounted"
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
