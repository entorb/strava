#!/bin/sh

cd "$(dirname "$0")/.."
out=$(mktemp)
trap 'rm -f "$out"' EXIT INT TERM

prek run --all-files --quiet >"$out" 2>&1
status=$?

if [ $status -ne 0 ]; then
  head -n 100 "$out"
else
  echo OK
fi
exit $status
