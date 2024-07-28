#!/bin/bash -e

wget "https://www.lesbonscomptes.com/pages/lesbonscomptes.gpg" -O "${ROOTFS_DIR}/etc/apt/keyrings/lesbonscomptes.gpg"
chown root:root "${ROOTFS_DIR}/etc/apt/keyrings/lesbonscomptes.gpg" && chmod 644 "${ROOTFS_DIR}/etc/apt/keyrings/lesbonscomptes.gpg"
install -v -m 644 files/upmpdcli.list "${ROOTFS_DIR}/etc/apt/sources.list.d/upmpdcli.list"

on_chroot << EOF
	apt-get update
EOF
