#!/bin/bash -e

wget https://raw.githubusercontent.com/johnlane/abcde/master/cddb-tool -O "${ROOTFS_DIR}/usr/local/bin/cddb-tool"
chown root:root "${ROOTFS_DIR}/usr/local/bin/cddb-tool" && chmod 755 "${ROOTFS_DIR}/usr/local/bin/cddb-tool"
install -v -m 755 -o 1000 -g 1000 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.cddb"
install -v -m 755 "files/cd-cue.sh" "${ROOTFS_DIR}/usr/local/bin/cd-cue.sh"
install -v -m 755 "files/mpc-cd.sh" "${ROOTFS_DIR}/usr/local/bin/mpc-cd.sh"
install -v -m 644 "files/cd-mount.service" "${ROOTFS_DIR}/etc/systemd/system/cd-mount.service"
install -v -m 644 "files/99-cd.rules" "${ROOTFS_DIR}/etc/udev/rules.d/99-cd.rules"

on_chroot << EOF
EOF
