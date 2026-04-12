#!/bin/sh

# ensure we are in the root dir
script_dir=$(cd $(dirname $0) && pwd)
cd $script_dir/..

# rm *.pl *.pm *.html gnuplot/*
rsync -rvhu --exclude=download entorb@entorb.net:html/strava-old/ ./
