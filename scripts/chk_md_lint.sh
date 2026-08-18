#!/bin/sh

# ensure we are in the root dir
cd "$(dirname "$0")/.."
out=$(mktemp)
trap 'rm -f "$out"' EXIT INT TERM

rumdl fmt .
rumdl check . >"$out" 2>&1
status=$?

if [ $status -ne 0 ]; then
    echo "Issues remaining, you can try:\nrumdl check . --fix"
    head -n 100 "$out"
fi
exit $status
