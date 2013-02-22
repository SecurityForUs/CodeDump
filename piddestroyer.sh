#!/bin/bash

[[ -z "$1" ]] && echo "No process given.  Usage: $0 <process name> [signal number]" && exit 1
[[ -z "$2" ]] && echo "No signal number given.  Using 9" && SIG=9 || SIG=$2

echo "Killing $1 with signal $SIG"

for i in `pidof "$1"`; do
	echo ">> Found pid: $i"
	kill -$SIG $i
done
