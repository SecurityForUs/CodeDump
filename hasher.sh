#!/bin/sh

HASH="$1"

for i in {6531..6535}
do
  H=$(echo -n "cs$i" | md5sum - | cut -d ' ' -f 1)
  if [ $H == $HASH ]; then
    echo "Hash is cs$i"
    exit 0
  fi
done

echo "No value found for hash $HASH"
exit 0
