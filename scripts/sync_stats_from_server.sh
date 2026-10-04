#!/bin/sh
set -e
cd "$(dirname "$0")/.."

rsync -vhu entorb@entorb.net:html/strava-old/activityStats2.js ./
rsync -vhu entorb@entorb.net:html/strava-old/activityStats2.html ./
# rsync -vhu download/123/stats-py/*.json entorb@entorb.net:html/strava-old/download/123/stats-py/
