#!/bin/sh
set -e
cd "$(dirname "$0")/.."

rsync -vhu ./*.html entorb@entorb.net:html/strava-old/
rsync -vhu ./*.pl entorb@entorb.net:html/strava-old/
rsync -vhu ./*.js entorb@entorb.net:html/strava-old/
rsync -vhu TMsStrava.pm entorb@entorb.net:html/strava-old/
rsync -vhu ./activityStats2.* entorb@entorb.net:html/strava-old/
rsync -vhu ./lib/* entorb@entorb.net:html/strava-old/lib/
