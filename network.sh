#!/bin/bash

# network.sh
# Tests a range of IPs (/24) to see if they are up.
# Short code to mostly test localized IPs.  Is not
# developed as a replacement for nmap.

# Written by Eric Hansen
# c/o Security For Us, LLC
# http://www.securityfor.us
# ehansen@securityfor.us

# /COLOR block - used for prettiness only
# Escape code
esc=`echo -en "\033"`

# Set colors
cc_red="${esc}[0;31m"
cc_green="${esc}[0;32m"
cc_yellow="${esc}[0;33m"
cc_blue="${esc}[0;34m"
cc_normal=`echo -en "${esc}[m\017"`
# /COLOR block

# IP address to start (leave off last octect)
IP_START="192.168.1."

# What IP to start off at (default: 192.168.1.1)
OCT_START=1

# What IP to end off at (default: 192.168.1.254)
OCT_END=254

# Counters for logistics
UP_HOSTS=0
DOWN_HOSTS=0

for (( i=$OCT_START; i <= $OCT_END; i++ ))
do
	# Execute a 1-packet ping
	PING_TEST=$(ping -c 1 $IP_START$i)

	# If 1 packet fails (100% pakcet loss) then chances are host is down
	UP=$(echo -n "$PING_TEST" | grep "100% packet loss")

	if [ -n "$UP" ]; then
		let DOWN_HOSTS++
		echo "Host $IP_START$i is ${cc_red}down${cc_normal}."
	else
		let UP_HOSTS++
		echo "Host $IP_START$i is ${cc_green}up${cc_normal}."
	fi
done

echo "Testing IPs $IP_START$OCT_START to $IP_START$OCT_END, there werew $DOWN_HOSTS down hosts and $UP_HOSTS up hosts."
