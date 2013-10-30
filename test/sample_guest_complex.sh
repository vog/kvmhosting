#!/bin/sh
set -eu

# Avoid hangup of HTTP proxy

(sleep 10s; svc -h /service/http) &

# Run virtual machine

exec kvm \
    -m 1G \
    -nographic \
    -boot order=c \
    -drive if=virtio,media=disk,file=/dev/vg0/complex \
    -net nic,model=virtio -net tap,ifname=tap_complex,script=no,downscript=no
