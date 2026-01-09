#!/bin/bash -e

on_chroot << EOF
	apt-get purge -y 'linux-headers-*' || true

	systemctl disable dphys-swapfile || true
	systemctl mask dphys-swapfile || true

	systemctl disable nfs-common rpcbind || true

	apt-get purge -y \
	build-essential gdb manpages-dev \
	python3-gpiozero python3-rpi.gpio python3-spidev \
	v4l-utils \
	nfs-common rpcbind \
	dphys-swapfile \
	rpicam-apps-lite || true

	apt-get autoremove -y
EOF
