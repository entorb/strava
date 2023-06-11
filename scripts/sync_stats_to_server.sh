#!/bin/sh

# ensure we are in the root dir
script_dir=$(cd $(dirname $0) && pwd)
cd $script_dir/..

rsync -vhu stats.py entorb@entorb.net:html/strava/
ssh entorb@entorb.net mkdir -p html/strava/download/123/stats-py/
rsync -vhu download/123/stats-py/*.json entorb@entorb.net:html/strava/download/123/stats-py/
