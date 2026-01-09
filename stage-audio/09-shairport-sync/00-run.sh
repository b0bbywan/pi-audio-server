#!/bin/bash -e

install -v -o 1000 -g 1000 -m 644 files/shairport-sync.service "${ROOTFS_DIR}/usr/lib/systemd/user/shairport-sync.service"

on_chroot << EOF
	systemctl disable shairport-sync.service
	/bin/su - "${FIRST_USER_NAME}" -c 'systemctl --user enable shairport-sync.service'
EOF
