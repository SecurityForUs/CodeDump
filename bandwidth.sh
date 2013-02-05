#!/bin/bash

# This requires the following iptables rules:
# iptables -I INPUT -d <virtual adapter IP>
# iptables -I OUTPUT -s <virtual adapter IP>
#
# Returns the bytes for each of the above rules (useful for SNMP mostly).

B=0

if [ "$1" == "INPUT" ]; then
	B=$(iptables -nxvL | head -n 3 | tail -n 1 | awk '{print $2}')
else
	B=$(iptables -nxvL | tail -n 1 | awk '{print $2}')
fi

echo "$B"
