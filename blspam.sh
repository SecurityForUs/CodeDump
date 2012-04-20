#!/bin/bash

# Fetch v2.0
# As the fetch.sh script no longer works, a new list gen was made.
# This one takes a list from Spam-IP.com and parses the CSV file.
# This is also a complete rewrite as well of fetch.sh
#
# Script created by Eric Hansen
# Security For Us, LLC https://www.securityfor.us/
# Contact: ehansen@securityfor.us
#
# Usage:
# ./blspam.sh [date]
# By default blspam.sh gets current date.  If you want to specify a certain
# date, pass it as a second argument in format mm-dd-yyyy (i.e.: 01/31/2028)
#
# The CSV file at spam-ip.com is updated hourly.
#

timer(){
    if [ $# -eq 0 ]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [ -z "$stime" ]; then
                stime=$etime
        fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}

SIPURL="http://spam-ip.com/csv_dump/spam-ip.com_"

if [ -n "$2" ]; then
	DATE="$2"
else
	DATE="`date +%m-%d-%Y`"
fi

SIPURL="$SIPURL$DATE.csv"
DUMP="/tmp/blips"
LIST="/tmp/ip_list"
IP_COUNT=0

echo -n "Emptying current blacklist..."
touch "$LIST"
echo "done."

FETCH_TIME=$(timer)

echo -n "Fetching IPs from: $SIPURL..."
wget -q "$SIPURL" -O "$DUMP"
echo "done."
printf '> Total time: %s\n' $(timer $FETCH_TIME)

echo -n "Removing first line of \"$DUMP\" before parsing..."
sed '1d' $DUMP > $DUMP.tmp
mv $DUMP.tmp $DUMP
echo "done."

echo -n "Parsing CSV file..."

PARSE_TIME=$(timer)

while read line
do
	IP=`echo -n "$line" | awk -F, '{print $2}' | tr -d ' '`
	echo "$IP" >> "$LIST"
	let IP_COUNT++
done < "$DUMP"

echo "done."

printf '> Total time: %s\n' $(timer $PARSE_TIME)

echo "Fetched a total of $IP_COUNT IPs (stored in $LIST)."
