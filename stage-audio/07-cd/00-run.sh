#!/bin/bash -e

install -v -m 755 -o 1000 -g 1000 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.cddb"
install -v -m 755 "files/mbdiscid.pl" "${ROOTFS_DIR}/usr/local/bin/mbdiscid.pl"
install -v -m 755 "files/cd-cue.sh" "${ROOTFS_DIR}/usr/local/bin/cd-cue.sh"
install -v -m 755 "files/mpc-cd.sh" "${ROOTFS_DIR}/usr/local/bin/mpc-cd.sh"
install -v -m 644 "files/cd-mount.service" "${ROOTFS_DIR}/etc/systemd/system/cd-mount.service"
install -v -m 644 "files/99-cd.rules" "${ROOTFS_DIR}/etc/udev/rules.d/99-cd.rules"

on_chroot << EOF
EOF
