#!/bin/sh
set -eu

# Network

install -o root -g root -m 700 -d /service/network
install -o root -g root -m 700 /dev/stdin /service/network/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'network'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF

# HTTP

install -o root -g root -m 700 -d /service/http
install -o root -g root -m 700 /dev/stdin /service/http/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'http'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF

# Guest: private

install -o root -g root -m 700 -d /service/guest_private
install -o root -g root -m 700 /dev/stdin /service/guest_private/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'guest'" --param name "'private'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF

# Guest: tcponly

install -o root -g root -m 700 -d /service/guest_tcponly
install -o root -g root -m 700 /dev/stdin /service/guest_tcponly/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'guest'" --param name "'tcponly'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF

# Guest: httponly

install -o root -g root -m 700 -d /service/guest_httponly
install -o root -g root -m 700 /dev/stdin /service/guest_httponly/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'guest'" --param name "'httponly'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF

# Guest: complex

install -o root -g root -m 700 -d /service/guest_complex
install -o root -g root -m 700 /dev/stdin /service/guest_complex/run <<'EOF'
#!/bin/sh
exec xsltproc --param service "'guest'" --param name "'complex'" /etc/kvmhosting/kvmhosting.xsl /etc/kvmhosting/config.xml
EOF
