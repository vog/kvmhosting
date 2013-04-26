#!/bin/sh
set -eu

# Configure HTTP proxy server

install -o root -g root -m 600 /dev/stdin /tmp/kvmhosting_nginx.conf <<'EOF'
daemon off;

user www-data;
error_log /var/log/nginx/error.log;

worker_processes 1;
events {
  worker_connections 1024;
}

http {
  access_log /var/log/nginx/access.log;
  proxy_buffering off;
  proxy_connect_timeout 1s;
  proxy_read_timeout 10m;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

  server {
    listen [::]:80 default;
  }

  # httponly
  upstream guest_httponly {
    server 10.0.3.2:80 fail_timeout=1s;
  }
  server {
    listen [::]:80;
    server_name httponly.example.com;
    location / {
      proxy_pass http://guest_httponly;
    }
  }

  # complex
  upstream guest_complex {
    server 10.0.5.2:80 fail_timeout=1s;
  }
  server {
    listen [::]:80;
    server_name .example.org example.com www.example.com images.example.com;
    location / {
      proxy_pass http://guest_complex;
    }
  }
}
EOF

# Run HTTP proxy server

exec nginx -c /tmp/kvmhosting_nginx.conf
