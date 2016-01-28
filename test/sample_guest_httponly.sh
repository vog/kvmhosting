#!/bin/sh
set -eu

# Avoid hangup of HTTP proxy

(sleep 10s; svc -h /service/http) &

# Run virtual machine

exec qemu-system-x86_64 \
    -enable-kvm \
    -m 512M \
    -nographic \
    -boot order=c \
    -drive if=virtio,media=disk,file=/dev/vg0/httponly \
    -net nic,model=virtio -net tap,ifname=tap_httponly,script=no,downscript=no
