<?xml version="1.0"?>
<!-- vim: set expandtab softtabstop=2 autoindent: -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="service"/>
  <xsl:param name="name"/>
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:text>#!/bin/sh&#xa;</xsl:text>
    <xsl:text>set -eu&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:choose>
      <xsl:when test="$service='guest'">
        <xsl:apply-templates select="host" mode="guest"/>
      </xsl:when>
      <xsl:when test="$service='http'">
        <xsl:apply-templates select="host" mode="http"/>
      </xsl:when>
      <xsl:when test="$service='network'">
        <xsl:apply-templates select="host" mode="network"/>
      </xsl:when>
      <xsl:when test="$service='update'">
        <xsl:apply-templates select="host" mode="update"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>echo 'Invalid service' >&amp;2&#xa;</xsl:text>
        <xsl:text>exit 1&#xa;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="host" mode="guest">
    <xsl:if test="not(guest[@name=$name])">
      <xsl:text>echo 'Invalid name' >&amp;2&#xa;</xsl:text>
      <xsl:text>exit 1&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="guest[@name=$name]" mode="guest"/>
  </xsl:template>
  <xsl:template match="guest" mode="guest">
    <xsl:text># Avoid hangup of HTTP proxy&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>(sleep 10s; svc -h /service/http) &amp;&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Run virtual machine&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>exec kvm \&#xa;</xsl:text>
    <xsl:text>    -m </xsl:text>
    <xsl:apply-templates select="@mem"/>
    <xsl:text> \&#xa;</xsl:text>
    <xsl:text>    -nographic \&#xa;</xsl:text>
    <xsl:text>    -boot order=c \&#xa;</xsl:text>
    <xsl:text>    -drive media=disk,file=</xsl:text>
    <xsl:apply-templates select="../@disk-prefix"/>
    <xsl:apply-templates select="@name"/>
    <xsl:text> \&#xa;</xsl:text>
    <xsl:text>    -net nic,model=virtio -net tap,ifname=tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>,script=no,downscript=no&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="host" mode="http">
    <xsl:text># Configure HTTP proxy server&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>install -o root -g root -m 600 /dev/stdin /tmp/kvm-hosting_nginx.conf &lt;&lt;'EOF'&#xa;</xsl:text>
    <xsl:text>daemon off;&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>user www-data;&#xa;</xsl:text>
    <xsl:text>error_log /var/log/nginx/error.log;&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>worker_processes 1;&#xa;</xsl:text>
    <xsl:text>events {&#xa;</xsl:text>
    <xsl:text>  worker_connections 1024;&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>http {&#xa;</xsl:text>
    <xsl:text>  access_log /var/log/nginx/access.log;&#xa;</xsl:text>
    <xsl:text>  proxy_buffering off;&#xa;</xsl:text>
    <xsl:text>  proxy_connect_timeout 1s;&#xa;</xsl:text>
    <xsl:text>  proxy_read_timeout 10m;&#xa;</xsl:text>
    <xsl:text>  proxy_set_header Host $host;&#xa;</xsl:text>
    <xsl:text>  proxy_set_header X-Real-IP $remote_addr;&#xa;</xsl:text>
    <xsl:text>  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>  server {&#xa;</xsl:text>
    <xsl:text>    listen [::]:80 default;&#xa;</xsl:text>
    <xsl:text>  }&#xa;</xsl:text>
    <xsl:apply-templates select="guest" mode="http"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>EOF&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Run HTTP proxy server&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>exec nginx -c /tmp/kvm-hosting_nginx.conf&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest[not(http)]" mode="http">
  </xsl:template>
  <xsl:template match="guest[http]" mode="http">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>  # </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>  upstream guest_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text> {&#xa;</xsl:text>
    <xsl:text>    server </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>2:80 fail_timeout=1s;&#xa;</xsl:text>
    <xsl:text>  }&#xa;</xsl:text>
    <xsl:text>  server {&#xa;</xsl:text>
    <xsl:text>    listen [::]:80;&#xa;</xsl:text>
    <xsl:text>    server_name</xsl:text>
    <xsl:apply-templates select="http" mode="http"/>
    <xsl:text>;&#xa;</xsl:text>
    <xsl:text>    location / {&#xa;</xsl:text>
    <xsl:text>      proxy_pass http://guest_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>;&#xa;</xsl:text>
    <xsl:text>    }&#xa;</xsl:text>
    <xsl:text>  }&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="http" mode="http">
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="@domain"/>
  </xsl:template>
  <xsl:template match="host" mode="network">
    <xsl:text># Configure TAP devices&#xa;</xsl:text>
    <xsl:apply-templates select="guest" mode="network-devices"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Enable port forwarding&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>echo 1 >/proc/sys/net/ipv4/ip_forward&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Configure iptables&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>iptables -t nat -F&#xa;</xsl:text>
    <xsl:text>iptables -t nat -X&#xa;</xsl:text>
    <xsl:text>iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -j SNAT --to-source </xsl:text>
    <xsl:apply-templates select="@snat-ip"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="guest" mode="network-iptables"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Configure DHCP server&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>install -o root -g root -m 600 /dev/stdin /tmp/kvm-hosting_dhcpd.conf &lt;&lt;EOF&#xa;</xsl:text>
    <xsl:text>option domain-name-servers $(&#xa;</xsl:text>
    <xsl:text>    sed -n 's/^nameserver \+\([0-9.]\+\)$/\1/p' /etc/resolv.conf | xargs | sed 's/ /, /g'&#xa;</xsl:text>
    <xsl:text>);&#xa;</xsl:text>
    <xsl:apply-templates select="guest" mode="network-dhcp"/>
    <xsl:text>EOF&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Run DHCP server&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>exec dhcpd -f -q -cf /tmp/kvm-hosting_dhcpd.conf</xsl:text>
    <xsl:apply-templates select="guest" mode="network-devicenames"/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest" mode="network-devices">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>ip tuntap add dev tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text> mode tap vnet_hdr 2>/dev/null \&#xa;</xsl:text>
    <xsl:text>    || true # Ignore error if TAP device already exists&#xa;</xsl:text>
    <xsl:text>ip link set tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text> up&#xa;</xsl:text>
    <xsl:text>ip addr flush dev tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>ip addr add </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>1/24 dev tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest" mode="network-iptables">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>iptables -t nat -N </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>_DNAT&#xa;</xsl:text>
    <xsl:text>iptables -t nat -A PREROUTING -j </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>_DNAT&#xa;</xsl:text>
    <xsl:text>iptables -t nat -A OUTPUT -j </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>_DNAT&#xa;</xsl:text>
    <xsl:apply-templates select="tcp" mode="network-iptables"/>
  </xsl:template>
  <xsl:template match="tcp" mode="network-iptables">
    <xsl:text>iptables -t nat -A </xsl:text>
    <xsl:apply-templates select="../@name"/>
    <xsl:text>_DNAT -d </xsl:text>
    <xsl:apply-templates select="@ext-ip"/>
    <xsl:text> -p tcp --dport </xsl:text>
    <xsl:apply-templates select="@ext-port"/>
    <xsl:text> -j DNAT --to-destination </xsl:text>
    <xsl:apply-templates select="../@net"/>
    <xsl:text>2:</xsl:text>
    <xsl:apply-templates select="@int-port"/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest" mode="network-dhcp">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>subnet </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>0 netmask 255.255.255.0 {&#xa;</xsl:text>
    <xsl:text>    range </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>2 </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>2;&#xa;</xsl:text>
    <xsl:text>    option routers </xsl:text>
    <xsl:apply-templates select="@net"/>
    <xsl:text>1;&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest" mode="network-devicenames">
    <xsl:text> tap_</xsl:text>
    <xsl:apply-templates select="@name"/>
  </xsl:template>
  <xsl:template match="host" mode="update">
    <xsl:text># Network&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="update-service">
      <xsl:with-param name="service" select="'network'"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># HTTP&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="update-service">
      <xsl:with-param name="service" select="'http'"/>
    </xsl:call-template>
    <xsl:apply-templates select="guest" mode="update"/>
  </xsl:template>
  <xsl:template name="update-service">
    <xsl:param name="service"/>
    <xsl:text>install -o root -g root -m 700 -d /service/</xsl:text>
    <xsl:value-of select="$service"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>install -o root -g root -m 700 /dev/stdin /service/</xsl:text>
    <xsl:value-of select="$service"/>
    <xsl:text>/run &lt;&lt;'EOF'&#xa;</xsl:text>
    <xsl:text>#!/bin/sh&#xa;</xsl:text>
    <xsl:text>exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml </xsl:text>
    <xsl:value-of select="$service"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>EOF&#xa;</xsl:text>
  </xsl:template>
  <xsl:template match="guest" mode="update">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text># Guest: </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>install -o root -g root -m 700 -d /service/guest_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>install -o root -g root -m 700 /dev/stdin /service/guest_</xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>/run &lt;&lt;'EOF'&#xa;</xsl:text>
    <xsl:text>#!/bin/sh&#xa;</xsl:text>
    <xsl:text>exec /opt/kvm-hosting.sh /etc/kvm-hosting/config.xml guest </xsl:text>
    <xsl:apply-templates select="@name"/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>EOF&#xa;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
