#!/bin/sh

# ensure we are in the root dir
cd "$(dirname "$0")/.."

failures=0
failed_list=""

echo "# code checks"

for f in "$(dirname "$0")"/chk_*.sh; do
    name=$(basename "$f" .sh)
    echo ""
    echo "## $name"
    sh "$f"
    if [ $? -ne 0 ]; then
        failures=$((failures + 1))
        failed_list="$failed_list $name"
    fi
done

echo ""
if [ "$failures" -eq 0 ]; then
    echo "All checks passed."
else
    echo "$failures checks failed:$failed_list"
    exit 1
fi
