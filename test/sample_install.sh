#!/bin/sh
set -eu

# Network

install -o root -g root -m 700 -d /service/network
install -o root -g root -m 700 /dev/stdin /service/network/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action network /etc/kvmhosting/config.xml | sh
EOF

# HTTP

install -o root -g root -m 700 -d /service/http
install -o root -g root -m 700 /dev/stdin /service/http/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action http /etc/kvmhosting/config.xml | sh
EOF

# Guest: private

install -o root -g root -m 700 -d /service/guest_private
install -o root -g root -m 700 /dev/stdin /service/guest_private/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action guest --stringparam name private /etc/kvmhosting/config.xml | sh
EOF

# Guest: tcponly

install -o root -g root -m 700 -d /service/guest_tcponly
install -o root -g root -m 700 /dev/stdin /service/guest_tcponly/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action guest --stringparam name tcponly /etc/kvmhosting/config.xml | sh
EOF

# Guest: httponly

install -o root -g root -m 700 -d /service/guest_httponly
install -o root -g root -m 700 /dev/stdin /service/guest_httponly/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action guest --stringparam name httponly /etc/kvmhosting/config.xml | sh
EOF

# Guest: httpsonly

install -o root -g root -m 700 -d /service/guest_httpsonly
install -o root -g root -m 700 /dev/stdin /service/guest_httpsonly/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action guest --stringparam name httpsonly /etc/kvmhosting/config.xml | sh
EOF

# Guest: complex

install -o root -g root -m 700 -d /service/guest_complex
install -o root -g root -m 700 /dev/stdin /service/guest_complex/run <<'EOF'
#!/bin/sh
exec xsltproc --stringparam action guest --stringparam name complex /etc/kvmhosting/config.xml | sh
EOF
