#!/bin/bash -e

install -v -m 644 files/asound.rc "${ROOTFS_DIR}/etc/asound.rc"
wget --max-redirect=10 "https://github.com/Spotifyd/spotifyd/releases/download/v${SPOTIFYD_VERSION}/spotifyd-linux-armv6-slim.tar.gz" -O - | tar xzf - -C "${ROOTFS_DIR}/usr/local/bin/"
chown root:root "${ROOTFS_DIR}/usr/local/bin/spotifyd" && chmod 755 "${ROOTFS_DIR}/usr/local/bin/spotifyd"
install -v -o 1000 -g 1000 -m 644 files/spotifyd.service "${ROOTFS_DIR}/usr/lib/systemd/user/spotifyd.service"

install -v -o 1000 -g 1000 -m 700 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/spotifyd"
install -v -o 1000 -g 1000 -m 600 files/spotifyd.conf "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/spotifyd/spotifyd.conf"
sed -i "s/TARGET_HOSTNAME/${TARGET_HOSTNAME}/g" "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/spotifyd/spotifyd.conf"

on_chroot << EOF
	/bin/su - "${FIRST_USER_NAME}" -c 'systemctl --user enable spotifyd.service'
EOF