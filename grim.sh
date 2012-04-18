#!/bin/bash

declare -a ID=( 1 2 3 4 5 6 7 8 9 10 )

for id in "${ID[@]}"; do
	NAME="servernames0$id"
	echo "$id = $NAME"
done
