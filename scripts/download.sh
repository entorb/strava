#!/bin/sh
set -e
cd "$(dirname "$0")/.."

# rm *.pl *.pm *.html gnuplot/*
rsync -rvhu --exclude=download entorb@entorb.net:html/strava-old/ ./
