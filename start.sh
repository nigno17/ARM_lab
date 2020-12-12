#!/bin/bash

qemu-system-arm \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -hda 2020-12-02-raspios-buster-armhf-full.img \
  -net nic -net user,hostfwd=tcp::5022-:22 \
  -dtb qemu-rpi-kernel/versatile-pb-buster.dtb \
  -kernel qemu-rpi-kernel/kernel-qemu-4.19.50-buster \
  -append 'root=/dev/sda2 panic=1' \
  -no-reboot
