#!/bin/sh
set -eu

# Network

install -o root -g root -m 700 -d /service/network
install -o root -g root -m 700 /dev/stdin /service/network/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml network
EOF

# HTTP

install -o root -g root -m 700 -d /service/http
install -o root -g root -m 700 /dev/stdin /service/http/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml http
EOF

# Guest: private

install -o root -g root -m 700 -d /service/guest_private
install -o root -g root -m 700 /dev/stdin /service/guest_private/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml guest private
EOF

# Guest: tcponly

install -o root -g root -m 700 -d /service/guest_tcponly
install -o root -g root -m 700 /dev/stdin /service/guest_tcponly/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml guest tcponly
EOF

# Guest: httponly

install -o root -g root -m 700 -d /service/guest_httponly
install -o root -g root -m 700 /dev/stdin /service/guest_httponly/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml guest httponly
EOF

# Guest: complex

install -o root -g root -m 700 -d /service/guest_complex
install -o root -g root -m 700 /dev/stdin /service/guest_complex/run <<'EOF'
#!/bin/sh
exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml guest complex
EOF
