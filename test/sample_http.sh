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
  client_max_body_size 0;
  proxy_buffering off;
  proxy_connect_timeout 1s;
  proxy_read_timeout 10m;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Host $host;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_set_header X-Forwarded-HTTPS 1;  # Workaround for mod_rpaf
  proxy_set_header X-Forwarded-Port 443;  # Workaround for mod_rpaf

  server {
    listen *:80 default;
  }

  # httponly
  upstream guest_httponly {
    server 10.0.3.2:80 fail_timeout=1s;
  }
  server {
    listen *:80;
    server_name httponly.example.com;
    location / {
      proxy_pass http://guest_httponly;
    }
  }

  # httpsonly
  upstream guest_httpsonly {
    server 10.0.4.2:80 fail_timeout=1s;
  }
  server {
    listen *:80;
    server_name httpsonly.example.com;
    location / {
      return 301 https://httpsonly.example.com;
    }
  }
  server {
    listen *:443 ssl;
    server_name httpsonly.example.com;
    ssl_certificate     /etc/ssl/private/httpsonly.example.com.pem;
    ssl_certificate_key /etc/ssl/private/httpsonly.example.com.pem;
    location / {
      proxy_pass http://guest_httpsonly;
    }
  }

  # complex
  upstream guest_complex {
    server 10.0.5.2:80 fail_timeout=1s;
  }
  server {
    listen *:80;
    server_name .example.org example.com www.example.com images.example.com;
    location / {
      proxy_pass http://guest_complex;
    }
  }
  server {
    listen *:80;
    server_name secure.example.com;
    location / {
      return 301 https://secure.example.com;
    }
  }
  server {
    listen *:443 ssl;
    server_name secure.example.com;
    ssl_certificate     /etc/ssl/private/secure.example.com.pem;
    ssl_certificate_key /etc/ssl/private/secure.example.com.pem;
    location / {
      proxy_pass http://guest_complex;
    }
  }
  server {
    listen *:80;
    server_name secure2.example.com;
    location / {
      return 301 https://secure2.example.com;
    }
    location /.well-known/acme-challenge {
      alias /var/www/letsencrypt/.well-known/acme-challenge;
    }
  }
  server {
    listen *:443 http2 ssl;
    server_name secure2.example.com;
    ssl_certificate     /etc/letsencrypt/live/secure2.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/secure2.example.com/privkey.pem;
    location / {
      proxy_pass http://guest_complex;
    }
  }
  server {
    listen *:80;
    server_name secure3.example.com;
    location / {
      return 301 https://secure3.example.com$request_uri;
    }
  }
  server {
    listen *:443 ssl;
    server_name secure3.example.com;
    ssl_certificate     /etc/ssl/private/secure3.example.com.pem;
    ssl_certificate_key /etc/ssl/private/secure3.example.com.pem;
    location / {
      proxy_pass http://guest_complex;
    }
  }
  server {
    listen *:80;
    server_name secure4.example.com;
    location / {
      return 301 https://secure4.example.com$request_uri;
    }
    location /.well-known/acme-challenge {
      alias /var/www/letsencrypt/.well-known/acme-challenge;
    }
  }
  server {
    listen *:443 ssl;
    server_name secure4.example.com;
    ssl_certificate     /etc/letsencrypt/live/secure4.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/secure4.example.com/privkey.pem;
    location / {
      proxy_pass http://guest_complex;
    }
  }
}
EOF

# Run HTTP proxy server

exec nginx -c /tmp/kvmhosting_nginx.conf
