#!/bin/sh
rm *.pl *.pm *.html gnuplot/*
rsync -rvhu --exclude=download entorb@entorb.net:html/strava/ ./

