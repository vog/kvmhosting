#!/bin/sh
set -eu

# Avoid hangup of HTTP proxy

(sleep 10s; svc -h /service/http) &

# Run virtual machine

exec kvm \
    -m 512M \
    -nographic \
    -boot order=c \
    -drive media=disk,file=/dev/vg0/httponly \
    -net nic,model=virtio -net tap,ifname=tap_httponly,script=no,downscript=no