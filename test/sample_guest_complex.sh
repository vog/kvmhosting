#!/bin/sh
set -eu

# Avoid hangup of HTTP proxy

(sleep 10s; svc -h /service/http) &

# Run virtual machine

exec qemu-system-x86_64 \
    -enable-kvm \
    -m 1G \
    -nographic \
    -boot order=c \
    -drive if=virtio,media=disk,file=/dev/vg0/complex \
    -drive if=virtio,media=disk,file=/dev/mapper/complex_extradisk1 \
    -drive if=virtio,media=disk,file=/dev/mapper/complex_extradisk2 \
    -net nic,model=virtio -net tap,ifname=tap_complex,script=no,downscript=no
