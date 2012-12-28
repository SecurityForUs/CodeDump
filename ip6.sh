#!/bin/bash

# This script is modified from the one found here: https://wiki.archlinux.org/index.php/IPv6_-_Tunnel_Broker_Setup
# Noticably this script now runs like this:
# $0 <start|stop> <device name>
#
# So if you want IPv6 traffic to be routed through wlan0, you would do:
# $0 start wlan0

. /etc/rc.conf
. /etc/rc.d/functions

if [ "$EUID" -ne 0 ]; then
  echo "You must run this as root"
  exit 1
fi

if_name=he6in4
server_ipv4='209.51.181.2' # HE Server Endpoint IP
client_ipv4=''
client_ipv6='2001:470:1f10:728::2' # Your HE-assigned client IP
link_mtu=1480
tunnel_ttl=255

if [ -n "$2" ]; then
  client_ipv4=$(ifconfig eth0 | grep netmask | awk '{print $2}')
fi

if [ -z "$client_ipv4" ]; then
  echo "Usage: $0 <start|stop> <device name>"
  exit 1
fi

echo "Tunneling data from IPv6 to $2 (IP: $client_ipv4)"

daemon_name=6in4-tunnel

# . /etc/rc.conf
# . /etc/rc.d/functions

case "$1" in
  start)
#    stat_busy "Starting $daemon_name daemon"

    ifconfig $if_name &>/dev/null
    if [ $? -eq 0 ]; then
      stat_busy "Interface $if_name already exists"
      stat_fail
      exit 1
    fi

    ip tunnel add $if_name mode sit remote $server_ipv4 local $client_ipv4 ttl $tunnel_ttl
    ip link set $if_name up mtu $link_mtu
    ip addr add $client_ipv6 dev $if_name
    ip route add ::/0 dev $if_name
    # Here is how you would add additional ips....which should be on the eth0 interface
    # ip addr add 2001:XXXX:XXXX:beef:beef:beef:beef:1/64 dev eth0
    # ip addr add 2001:XXXX:XXXX:beef:beef:beef:beef:2/64 dev eth0
    # ip addr add 2001:XXXX:XXXX:beef:beef:beef:beef:3/64 dev eth0

    add_daemon $daemon_name
    stat_done
    ;;

  stop)
    stat_busy "Stopping $daemon_name daemon"

    ifconfig $if_name &>/dev/null
    if [ $? -ne 0 ]; then
      stat_busy "Interface $if_name does not exist"
      stat_fail
      exit 1
    fi

    ip link set $if_name down
    ip tunnel del $if_name

    rm_daemon $daemon_name
    stat_done
    ;;

  *)
    echo "usage: $0 {start|stop}"
esac
exit 0
