#!/bin/sh

# ensure we are in the root dir
cd "$(dirname "$0")/.."
out=$(mktemp)
trap 'rm -f "$out"' EXIT INT TERM

uvx ryl@0.21.0 check -d '{extends: default, rules: {line-length: disable, truthy: disable}, ignore: [pnpm-lock.yaml]}' . --fix >"$out" 2>&1
status=$?

if [ $status -ne 0 ]; then
    head -n 100 "$out"
fi
exit $status
