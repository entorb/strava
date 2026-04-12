#!/bin/sh

# ensure we are in the root dir
script_dir=$(cd $(dirname $0) && pwd)
cd $script_dir/..

mkdir -p lib

# ECharts
ver=5.4.2
wget -q https://raw.githubusercontent.com/apache/echarts/$ver/dist/echarts.min.js -O lib/echarts-$ver.min.js
wget -q https://raw.githubusercontent.com/apache/echarts/$ver/dist/echarts.min.map -O lib/echarts-$ver.min.map

# Tabulator
ver=5.5.0

mkdir -p tmp-dl
wget -q https://github.com/olifolkerd/tabulator/archive/refs/tags/$ver.zip -O tmp-dl/tabulator-$ver.zip

cd tmp-dl
unzip -q -o tabulator-$ver.zip
cd ..

mv tmp-dl/tabulator-$ver/dist/js/tabulator.min.js lib/tabulator-5.4.min.js
mv tmp-dl/tabulator-$ver/dist/js/tabulator.min.js.map lib/tabulator.min.js.map
mv tmp-dl/tabulator-$ver/dist/css/tabulator.min.css lib/tabulator.min.css
mv tmp-dl/tabulator-$ver/dist/css/tabulator.min.css.map lib/tabulator.min.css.map

# # JQuery
# ver=3.7.0
# wget -q https://code.jquery.com/jquery-$ver.min.js -O lib/jquery-$ver.min.js
# wget -q https://code.jquery.com/jquery-$ver.min.map -O lib/jquery-$ver.min.map

# Cleanup
rm -r tmp-dl

rsync -vhu lib/* entorb@entorb.net:html/strava-old/libs/
