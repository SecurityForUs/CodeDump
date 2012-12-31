#!/bin/sh

# Code is swipped from http://legroom.net/2010/05/02/port-testing-and-scanning-bash
#
# Usage: ./portscan.sh <ip>
#
# Change range in {...} block as you please.

function port() {
        (echo > /dev/tcp/$1/$2) &> /dev/null
        if [ $? -eq 0 ]; then
                echo "$1:$2 open"
        else
                echo "$1:$2 closed"
        fi
}

for i in {22..80}; do
        port $1 $i
done
