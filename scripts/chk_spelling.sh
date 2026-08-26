#!/bin/sh

# ensure we are in the root dir
cd "$(dirname "$0")/.."

pnpm dlx cspell-cli@10.0.1 --unique --words-only . >cspell-words-missing.txt 2>/dev/null
status=$?

if [ $status -ne 0 ]; then
  echo "Found unknown spellings, see cspell-words-missing.txt. Fix or transfer to cspell-words.txt"
else
  rm cspell-words-missing.txt
fi

exit $status
