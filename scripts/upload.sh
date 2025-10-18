#!/bin/sh

# ensure we are in the root dir
script_dir=$(cd $(dirname $0) && pwd)
cd $script_dir/..

rsync -vhu *.html entorb@entorb.net:html/strava/
rsync -vhu *.pl entorb@entorb.net:html/strava/
rsync -vhu TMsStrava.pm entorb@entorb.net:html/strava/
rsync -vhu activityStats2.* entorb@entorb.net:html/strava/
rsync -vhu lib/* entorb@entorb.net:html/strava/lib/
