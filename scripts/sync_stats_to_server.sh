#!/bin/sh

# ensure we are in the root dir
script_dir=$(cd $(dirname $0) && pwd)
cd $script_dir/..

rsync -vhu activityStats2.py entorb@entorb.net:html/strava-old/
ssh entorb@entorb.net mkdir -p html/strava-old/download/123
rsync -vhu download/123/*.json entorb@entorb.net:html/strava-old/download/123/
