<?xml version="1.0"?>
<!-- vim: set expandtab softtabstop=2 autoindent: -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ext="http://exslt.org/common">
  <xsl:param name="action" select="'install'"/>
  <xsl:param name="name"/>
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:variable name="output">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:for-each select="ext:node-set($output)/_">
      <xsl:value-of select="."/>
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="host">
    <_>#!/bin/sh</_>
    <_>set -eu</_>
    <_/>
    <xsl:choose>
      <xsl:when test="$action='guest'">
        <xsl:apply-templates select="." mode="guest"/>
      </xsl:when>
      <xsl:when test="$action='http'">
        <xsl:apply-templates select="." mode="http"/>
      </xsl:when>
      <xsl:when test="$action='http_nossl'">
        <xsl:apply-templates select="." mode="http">
          <xsl:with-param name="http_mode" select="'nossl'"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$action='network'">
        <xsl:apply-templates select="." mode="network"/>
      </xsl:when>
      <xsl:when test="$action='install'">
        <xsl:apply-templates select="." mode="install"/>
      </xsl:when>
      <xsl:otherwise>
        <_>echo 'Invalid action' >&amp;2</_>
        <_>exit 1</_>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="host" mode="guest">
    <xsl:if test="not(guest[@name=$name])">
      <_>echo 'Invalid name' >&amp;2</_>
      <_>exit 1</_>
    </xsl:if>
    <xsl:apply-templates select="guest[@name=$name]" mode="guest"/>
  </xsl:template>
  <xsl:template match="guest" mode="guest">
    <_># Avoid hangup of HTTP proxy</_>
    <_/>
    <_>(sleep 10s; svc -h /service/http) &amp;</_>
    <_/>
    <_># Run virtual machine</_>
    <_/>
    <_>exec qemu-system-x86_64 \</_>
    <_>    -enable-kvm \</_>
    <_>    -m <xsl:apply-templates select="@mem"/> \</_>
    <_>    -nographic \</_>
    <_>    -boot order=c \</_>
    <_>    -drive if=virtio,media=disk,file=<xsl:apply-templates select="../@disk-prefix"/><xsl:apply-templates select="@name"/> \</_>
    <xsl:for-each select="extra-disk">
      <_>    -drive if=virtio,media=disk,file=<xsl:apply-templates select="@dev"/> \</_>
    </xsl:for-each>
    <_>    -net nic,model=virtio -net tap,ifname=tap_<xsl:apply-templates select="@name"/>,script=no,downscript=no</_>
  </xsl:template>
  <xsl:template match="host" mode="http">
    <xsl:param name="http_mode"/>
    <_># Configure HTTP proxy server</_>
    <_/>
    <_>install -o root -g root -m 600 /dev/stdin /run/kvmhosting_nginx.conf &lt;&lt;'EOF'</_>
    <_>daemon off;</_>
    <_/>
    <_>user www-data;</_>
    <_>error_log /var/log/nginx/error.log;</_>
    <_/>
    <_>worker_processes 1;</_>
    <_>events {</_>
    <_>  worker_connections 1024;</_>
    <_>}</_>
    <_/>
    <_>http {</_>
    <_>  access_log /var/log/nginx/access.log;</_>
    <_>  client_max_body_size 0;</_>
    <_>  proxy_buffering off;</_>
    <_>  proxy_connect_timeout 1s;</_>
    <_>  proxy_read_timeout 10m;</_>
    <_>  proxy_set_header Host $host;</_>
    <_>  proxy_set_header X-Real-IP $remote_addr;</_>
    <_>  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;</_>
    <_>  proxy_set_header X-Forwarded-Host $host;</_>
    <_>  proxy_set_header X-Forwarded-Proto $scheme;</_>
    <_>  proxy_set_header X-Forwarded-HTTPS 1;  # Workaround for mod_rpaf</_>
    <_>  proxy_set_header X-Forwarded-Port 443;  # Workaround for mod_rpaf</_>
    <_/>
    <_>  server {</_>
    <_>    listen *:80 default;</_>
    <_>  }</_>
    <xsl:apply-templates select="guest[http|http-ssl]" mode="http">
      <xsl:with-param name="http_mode" select="$http_mode"/>
    </xsl:apply-templates>
    <_>}</_>
    <_>EOF</_>
    <_/>
    <_># Run HTTP proxy server</_>
    <_/>
    <_>exec nginx -c /run/kvmhosting_nginx.conf</_>
  </xsl:template>
  <xsl:template match="guest[http|http-ssl]" mode="http">
    <xsl:param name="http_mode"/>
    <_/>
    <_>  # <xsl:apply-templates select="@name"/></_>
    <_>  upstream guest_<xsl:apply-templates select="@name"/> {</_>
    <_>    server <xsl:apply-templates select="@net"/>2:80 fail_timeout=1s;</_>
    <_>  }</_>
    <xsl:if test="http">
      <_>  server {</_>
      <_>    listen *:80;</_>
      <_>    server_name<xsl:apply-templates select="http/@domain" mode="http"/>;</_>
      <_>    location / {</_>
      <_>      proxy_pass http://guest_<xsl:apply-templates select="@name"/>;</_>
      <_>    }</_>
      <_>  }</_>
    </xsl:if>
    <xsl:for-each select="http-ssl">
      <_>  server {</_>
      <_>    listen *:80;</_>
      <_>    server_name <xsl:apply-templates select="@domain"/>;</_>
      <_>    location / {</_>
      <xsl:choose>
        <xsl:when test="@redirect='unsafe'">
          <_>      return 301 https://<xsl:apply-templates select="@domain"/>$request_uri;</_>
        </xsl:when>
        <xsl:otherwise>
          <_>      return 301 https://<xsl:apply-templates select="@domain"/>;</_>
        </xsl:otherwise>
      </xsl:choose>
      <_>    }</_>
      <xsl:if test="@cert='letsencrypt'">
        <_>    location /.well-known/acme-challenge {</_>
        <_>      alias /var/www/letsencrypt/.well-known/acme-challenge;</_>
        <_>    }</_>
      </xsl:if>
      <_>  }</_>
      <xsl:if test="$http_mode!='nossl'">
        <_>  server {</_>
        <xsl:choose>
          <xsl:when test="@protocol='http2'">
            <_>    listen *:443 http2 ssl;</_>
          </xsl:when>
          <xsl:otherwise>
            <_>    listen *:443 ssl;</_>
          </xsl:otherwise>
        </xsl:choose>
        <_>    server_name <xsl:apply-templates select="@domain"/>;</_>
        <xsl:choose>
          <xsl:when test="@cert='letsencrypt'">
            <_>    ssl_certificate     /etc/letsencrypt/live/<xsl:apply-templates select="@domain"/>/fullchain.pem;</_>
            <_>    ssl_certificate_key /etc/letsencrypt/live/<xsl:apply-templates select="@domain"/>/privkey.pem;</_>
          </xsl:when>
          <xsl:otherwise>
            <_>    ssl_certificate     /etc/ssl/private/<xsl:apply-templates select="@domain"/>.pem;</_>
            <_>    ssl_certificate_key /etc/ssl/private/<xsl:apply-templates select="@domain"/>.pem;</_>
          </xsl:otherwise>
        </xsl:choose>
        <_>    location / {</_>
        <_>      proxy_pass http://guest_<xsl:apply-templates select="../@name"/>;</_>
        <_>    }</_>
        <_>  }</_>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="@domain" mode="http">
    <_ xml:space="preserve"><xsl:text> </xsl:text><xsl:apply-templates select="."/></_>
  </xsl:template>
  <xsl:template match="host" mode="network">
    <_># Configure TAP devices</_>
    <xsl:apply-templates select="guest" mode="network-devices"/>
    <_/>
    <_># Enable port forwarding</_>
    <_/>
    <_>echo 1 >/proc/sys/net/ipv4/conf/all/forwarding</_>
    <xsl:if test="guest/@ipv6">
      <_>echo 1 >/proc/sys/net/ipv6/conf/all/forwarding</_>
    </xsl:if>
    <_/>
    <_># Configure iptables</_>
    <_/>
    <_>iptables -t nat -F</_>
    <_>iptables -t nat -X</_>
    <_>iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j SNAT --to-source <xsl:apply-templates select="@snat-ip"/></_>
    <xsl:apply-templates select="guest" mode="network-iptables"/>
    <_/>
    <_># Configure DHCP server</_>
    <_/>
    <_>install -o root -g root -m 600 /dev/stdin /etc/dhcp/kvmhosting_dhcpd.conf &lt;&lt;EOF</_>
    <_>option domain-name-servers $(</_>
    <_>    sed -n 's/^nameserver \+\([0-9.]\+\)$/\1/p' /etc/resolv.conf | xargs | sed 's/ /, /g'</_>
    <_>);</_>
    <xsl:apply-templates select="guest" mode="network-dhcp"/>
    <_>EOF</_>
    <_/>
    <_># Run DHCP server</_>
    <_/>
    <_>exec dhcpd -f -q -cf /etc/dhcp/kvmhosting_dhcpd.conf<xsl:apply-templates select="guest" mode="network-devicenames"/></_>
  </xsl:template>
  <xsl:template match="guest" mode="network-devices">
    <_/>
    <_>ip tuntap add dev tap_<xsl:apply-templates select="@name"/> mode tap vnet_hdr 2>/dev/null \</_>
    <_>    || true # Ignore error if TAP device already exists</_>
    <_>ip link set tap_<xsl:apply-templates select="@name"/> up</_>
    <_>ip addr flush dev tap_<xsl:apply-templates select="@name"/></_>
    <_>ip addr add <xsl:apply-templates select="@net"/>1/24 dev tap_<xsl:apply-templates select="@name"/></_>
    <xsl:if test="@ipv6">
      <_>ip addr add fe80::1 peer <xsl:apply-templates select="@ipv6"/>/128 dev tap_<xsl:apply-templates select="@name"/></_>
    </xsl:if>
  </xsl:template>
  <xsl:template match="guest[not(tcp)]" mode="network-iptables">
  </xsl:template>
  <xsl:template match="guest[tcp]" mode="network-iptables">
    <_/>
    <_>iptables -t nat -N <xsl:apply-templates select="@name"/>_DNAT</_>
    <_>iptables -t nat -A PREROUTING -j <xsl:apply-templates select="@name"/>_DNAT</_>
    <_>iptables -t nat -A OUTPUT -j <xsl:apply-templates select="@name"/>_DNAT</_>
    <xsl:apply-templates select="tcp" mode="network-iptables"/>
  </xsl:template>
  <xsl:template match="tcp" mode="network-iptables">
    <_>
      <_>iptables -t nat -A <xsl:apply-templates select="../@name"/>_DNAT</_>
      <_> -d <xsl:apply-templates select="@ext-ip"/></_>
      <_> -p tcp</_>
      <_> --dport <xsl:apply-templates select="@ext-port"/></_>
      <_> -j DNAT</_>
      <_> --to-destination <xsl:apply-templates select="../@net"/>2:<xsl:apply-templates select="@int-port"/></_>
    </_>
  </xsl:template>
  <xsl:template match="guest" mode="network-dhcp">
    <_/>
    <_># <xsl:apply-templates select="@name"/></_>
    <_>subnet <xsl:apply-templates select="@net"/>0 netmask 255.255.255.0 {</_>
    <_>    range <xsl:apply-templates select="@net"/>2 <xsl:apply-templates select="@net"/>2;</_>
    <_>    option routers <xsl:apply-templates select="@net"/>1;</_>
    <_>}</_>
  </xsl:template>
  <xsl:template match="guest" mode="network-devicenames">
    <_ xml:space="preserve"> tap_<xsl:apply-templates select="@name"/></_>
  </xsl:template>
  <xsl:template match="host" mode="install">
    <_># Network</_>
    <_/>
    <xsl:call-template name="install-service">
      <xsl:with-param name="action" select="'network'"/>
      <xsl:with-param name="service" select="'network'"/>
    </xsl:call-template>
    <_/>
    <_># Let's Encrypt web directory for ACME challenges</_>
    <_/>
    <_>install -o root -g root -m 755 -d /var/www/letsencrypt</_>
    <_/>
    <_># HTTP without SSL for Let's Encrypt initial certificates</_>
    <_/>
    <xsl:call-template name="install-service">
      <xsl:with-param name="action" select="'http_nossl'"/>
      <xsl:with-param name="service" select="'http'"/>
    </xsl:call-template>
    <_/>
    <_># Let's Encrypt initial certificates</_>
    <_/>
    <xsl:for-each select="guest/http-ssl[@cert='letsencrypt']">
      <_>if [ ! -e /etc/letsencrypt/live/<xsl:apply-templates select="@domain"/> ]; then</_>
      <_>    certbot certonly -n --agree-tos --rsa-key-size 4096 --webroot -t -m <xsl:apply-templates select="../../@letsencrypt-email"/> -w /var/www/letsencrypt -d <xsl:apply-templates select="@domain"/></_>
      <_>fi</_>
    </xsl:for-each>
    <_/>
    <_># HTTP</_>
    <_/>
    <xsl:call-template name="install-service">
      <xsl:with-param name="action" select="'http'"/>
      <xsl:with-param name="service" select="'http'"/>
    </xsl:call-template>
    <_/>
    <_># Let's Encrypt cronjob for updating certificates</_>
    <_/>
    <_>install -o root -g root -m 600 /dev/stdin /etc/cron.d/letsencrypt &lt;&lt;'EOF'</_>
    <_>42 * * * *  root  /usr/bin/certbot renew --quiet --post-hook '/usr/bin/svc -t /service/http'</_>
    <_>EOF</_>
    <xsl:apply-templates select="guest" mode="install"/>
  </xsl:template>
  <xsl:template name="install-service">
    <xsl:param name="action"/>
    <xsl:param name="service"/>
    <_>install -o root -g root -m 700 -d /service/<xsl:value-of select="$service"/></_>
    <_>install -o root -g root -m 700 /dev/stdin /service/<xsl:value-of select="$service"/>/run &lt;&lt;'EOF'</_>
    <_>#!/bin/bash</_>
    <_>exec sh &lt;(xsltproc --stringparam action <xsl:value-of select="$action"/> /etc/kvmhosting/config.xml)</_>
    <_>EOF</_>
    <_>svc -t /service/<xsl:value-of select="$service"/></_>
  </xsl:template>
  <xsl:template match="guest" mode="install">
    <_/>
    <_># Guest: <xsl:apply-templates select="@name"/></_>
    <_/>
    <_>install -o root -g root -m 700 -d /service/guest_<xsl:apply-templates select="@name"/></_>
    <_>install -o root -g root -m 700 /dev/stdin /service/guest_<xsl:apply-templates select="@name"/>/run &lt;&lt;'EOF'</_>
    <_>#!/bin/bash</_>
    <_>exec sh &lt;(xsltproc --stringparam action guest --stringparam name <xsl:apply-templates select="@name"/> /etc/kvmhosting/config.xml)</_>
    <_>EOF</_>
  </xsl:template>
</xsl:stylesheet>
