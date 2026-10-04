#!/bin/sh
set -e
cd "$(dirname "$0")/.."

rsync -vhu activityStats2.py entorb@entorb.net:html/strava-old/
ssh entorb@entorb.net mkdir -p html/strava-old/download/123
rsync -vhu download/123/*.json entorb@entorb.net:html/strava-old/download/123/
