#!/bin/bash -e

install -v -m 755 files/pulse-acl.sh "${ROOTFS_DIR}/usr/local/bin/pulse-acl.sh"
install -v -m 644 files/rasponkyo-pulse.service "${ROOTFS_DIR}/usr/lib/systemd/user/rasponkyo-pulse.service"

on_chroot << EOF
    /bin/su - "${FIRST_USER_NAME}" -c 'systemctl --user enable pulseaudio.service'
    /bin/su - "${FIRST_USER_NAME}" -c 'systemctl --user enable rasponkyo-pulse.service'
EOF
