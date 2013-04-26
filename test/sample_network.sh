#!/bin/sh
set -eu

# Configure TAP devices

ip tuntap add dev tap_private mode tap vnet_hdr 2>/dev/null \
    || true # Ignore error if TAP device already exists
ip link set tap_private up
ip addr flush dev tap_private
ip addr add 10.0.1.1/24 dev tap_private

ip tuntap add dev tap_tcponly mode tap vnet_hdr 2>/dev/null \
    || true # Ignore error if TAP device already exists
ip link set tap_tcponly up
ip addr flush dev tap_tcponly
ip addr add 10.0.2.1/24 dev tap_tcponly

ip tuntap add dev tap_httponly mode tap vnet_hdr 2>/dev/null \
    || true # Ignore error if TAP device already exists
ip link set tap_httponly up
ip addr flush dev tap_httponly
ip addr add 10.0.3.1/24 dev tap_httponly

ip tuntap add dev tap_complex mode tap vnet_hdr 2>/dev/null \
    || true # Ignore error if TAP device already exists
ip link set tap_complex up
ip addr flush dev tap_complex
ip addr add 10.0.5.1/24 dev tap_complex

# Enable port forwarding

echo 1 >/proc/sys/net/ipv4/ip_forward

# Configure iptables

iptables -t nat -F
iptables -t nat -X
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j SNAT --to-source 192.168.0.1

iptables -t nat -N tcponly_DNAT
iptables -t nat -A PREROUTING -j tcponly_DNAT
iptables -t nat -A OUTPUT -j tcponly_DNAT
iptables -t nat -A tcponly_DNAT -d 192.168.0.2 -p tcp --dport 2022 -j DNAT --to-destination 10.0.2.2:22

iptables -t nat -N complex_DNAT
iptables -t nat -A PREROUTING -j complex_DNAT
iptables -t nat -A OUTPUT -j complex_DNAT
iptables -t nat -A complex_DNAT -d 192.168.0.2 -p tcp --dport 4022 -j DNAT --to-destination 10.0.5.2:22
iptables -t nat -A complex_DNAT -d 192.168.0.3 -p tcp --dport 25 -j DNAT --to-destination 10.0.5.2:25

# Configure DHCP server

install -o root -g root -m 600 /dev/stdin /tmp/kvmhosting_dhcpd.conf <<EOF
option domain-name-servers $(
    sed -n 's/^nameserver \+\([0-9.]\+\)$/\1/p' /etc/resolv.conf | xargs | sed 's/ /, /g'
);

# private
subnet 10.0.1.0 netmask 255.255.255.0 {
    range 10.0.1.2 10.0.1.2;
    option routers 10.0.1.1;
}

# tcponly
subnet 10.0.2.0 netmask 255.255.255.0 {
    range 10.0.2.2 10.0.2.2;
    option routers 10.0.2.1;
}

# httponly
subnet 10.0.3.0 netmask 255.255.255.0 {
    range 10.0.3.2 10.0.3.2;
    option routers 10.0.3.1;
}

# complex
subnet 10.0.5.0 netmask 255.255.255.0 {
    range 10.0.5.2 10.0.5.2;
    option routers 10.0.5.1;
}
EOF

# Run DHCP server

exec dhcpd -f -q -cf /tmp/kvmhosting_dhcpd.conf tap_private tap_tcponly tap_httponly tap_complex
