#!/bin/sh

# This script fetches all reportedly bad IPs from countryblocks.net's server based on country code, and
# spits them out to a file.  This way you can use these IPs for tcp_wrappers and iptables.
#
# This script was writen by Eric Hansen, owner of Security For Us, LLC.  Last modified: 03/16/2012
#
# You are free to use this script for any purpose.  However, Eric Hansen, nor Security For Us, LLC are responsible
# for any issues that may arise from using this script, both directly and indrectly.
#
# The intent of this script is provide an automagic update to fetching IPs so they can be blocked.
#
# Its suggested that this be set up as a cron job to run daily for the most secure solution.
# If you use this list to populate iptables, it is advisable to make sure the IP doesn't already exist before adding them to a chain.

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
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}

SCRIPT_TIME=$(timer)

CURL_CHECK=`curl --version | grep curl`
USE_CURL=1

if [ -z "$CURL_CHECK" ]; then
	echo "cURL (command line version) is recommended for use.  Attempting to use wget instead."
	USE_CURL=0
fi

j=0

OUTPUT="/tmp/bad_ips"
COUNTRIES=""
CL="AF AX AL DZ AS AD AO AI AQ AG AR AM AW AP AU AT AZ BS BH BD BB BY BE BZ BJ BM BT XA BO BQ BA BW BV BR IO BN BG BF BI KH CM CA CV KY CF TD CL CN CX CC CO KM CG CD CK CR CI HR CU CW CY CZ DK DJ DM DO EC EG SV GQ ER EE ET EU FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG GN GW GY HT HM VA HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ KE KI KP KR CS KW KG LA LV LB LS LR LY LI LT LU MO MK MG MW MY MV ML MT MH MQ MR MU YT MX FM MD MC MN ME MS MA MZ MM NA NR NP NL AN NC NZ NI NE NG NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA RE RO RU RW BL SH KN LC MF PM VC WS SM ST SA SN RS SC SL SG SX SK SI SB SO ZA GS ES LK SD SR SJ SZ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV UG UA AE GB US UM UY UZ VU VE VN VG VI WF EH YE ZM ZW"
CBURL="http://www.countryipblocks.net/country-blocks/select-formats/"

echo "-- Bad IP Fetcher v1.0 --"
echo "Script Usage: $0 [country list] [IP list filename]"
echo "- Country list: List of 2-character code countries to get reportedly bad IPs from."
echo "- IP list filename: This is the output file where the IPs will be stored."
echo "If only 1 argument is given, it is assumed to be the output filename."
echo "A word of warning, this script may take a while as it checks every IP address to see if it is already in the ban list."

if [ "$#" -lt 2 ]; then
    # Less than 2 options given
    if [ "$#" -eq 1 ]; then
	# Only option given, assume its output file
        OUTPUT="$1"
    fi

    # Counter for countries to parse
    j=0
    for i in `echo -n "$CL" | awk '{print $j}'`; do
        COUNTRIES="$COUNTRIES&countries[]=$i"
        j=$(($j + 1))
    done
else
    OUTPUT="$2"

    j=0
    for i in `echo -n $1 | awk '{print $j}'`; do
        COUNTRIES="$COUNTRIES&countries[]=$i"
        j=$(($j + 1))
    done
fi

# Is this a fresh fetching? (default: no)
NEW=0

# If output file is empty assume fresh fetching
if [ -z `cat $OUTPUT` ]; then
	NEW=1
fi

# POST format for cURL
FIELDS="format1=1&choose_countries=Choose Countries$COUNTRIES"

# Output some information
echo "Output file: $OUTPUT"
echo "Fetching $j countries."
echo "Use cURL: $USE_CURL"
echo "[`date +%r`] Fetching IP list from $CBURL"

FETCH_TIME=$(timer)

# Get data
if [ $USE_CURL -eq 1 ]; then
	echo -n "Starting cURL..."
	DATA=`curl -s -d "$FIELDS" -o data.html $CBURL`
	echo "done."
else
	echo -n "Starting wget..."
	DATA=`wget --post-data="$FIELDS" -q -O data.html $CBURL`
	echo "done."
fi

printf '!! Elapsed time to HTML for IPs: %s\n' $(timer $FETCH_TIME)

found=0
stored=0
denied=0

echo -n "[`date +%r`] Fetching IPs and storing them in $OUTPUT..."

IP_LIST=`cat $OUTPUT`

STORE_TIME=$(timer)

for i in `cat data.html | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}'`; do
	if [ $NEW -eq 1 ]; then
		echo $i >> $OUTPUT
		stored=$(($stored + 1))
	else
		EXISTS=`grep $i $OUTPUT`

		if [ -z "$EXISTS" ]; then
			echo $i >> $OUTPUT
			stored=$(($stored + 1))
		else
			denied=$(($denied + 1))
		fi
	fi

	found=$(($found + 1))
done
echo "done."

printf '!! Elapsed time for storing IP list: %s\n' $(timer $STORE_TIME)

echo "[`date +%r`] A total of $found blacklisted IPs were fetched, $0 stored $stored of them in $OUTPUT, while $denied were already present."

printf '!! Script execution time: %s\n' $(timer $SCRIPT_TIME)
