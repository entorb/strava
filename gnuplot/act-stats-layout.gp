# settings for terminal
# did not work when move into act-stats-layout.gp
# font Arial was not installed on uberspace
# svg or png
set terminal png size 800,400 font myFont
# crop
# set terminal png giant size 3*360,3*180 font "Arial,9"


# settings for plot layout
set grid
# print url to bottom right corner
set label 2 "https://entorb.net/strava" at screen 0.999, screen 0.01 right font myFont.",9"  textcolor rgb "black"

# settings for lines
# TODO: dashtype does not work here
set style increment user # important!!! switch between linetypes (default) and userdefined linestyles
# set dashtype 2 " - "
# set dashtype 2 (2,4,2,6)
set style line  1 linetype 2 linewidth 1 pointsize 1.5 pt 4 linecolor rgb "blue" # ls 1 = boxes and lines
set style line  2 linetype 6 linewidth 3 linecolor rgb "dark-blue" # slope
set style line  3 linetype 6 linewidth 3 linecolor rgb "gray60" # mean all data
set style line  4 linetype 6 linewidth 3 linecolor rgb "gray30" # mean one year
# dashtype 2

# settings for labels and tics
set title "" offset 0,-0.8
set xlabel "Date" # offset 4,-5
#set ylabel "" offset screen 0.0
unset ylabel

set label 1 "Y-Label"  at screen 0.02, graph 0.5 center rotate by 90 front font myFont.",12"
set label 2 "Y2-Label" at screen 0.98, graph 0.5 center rotate by 90 front font myFont.",12"
set label 2 ""

# set y2label "Count average" offset -2.5 textcolor ls 2
set xtics rotate
set ytics mirror
# set y2tics nomirror textcolor ls 2
# set y2tics 25
set xtics 1
set mxtics 4

# settings for key / legend
set key box top left width +1 samplen 2
# reverse invert Left

# settings for plot range
set xrange [int(date_min)-0.5:int(date_max)+1+0.5]
# month-plot: reduce display to 5 years
if (date_aggregation eq "Month")   set xrange [int(date_max)-5-0.5/12:]
# set xrange [*:-0.5]
set yrange [0:*]
# set y2range [0:100]


# settings for boxes
# set style data histograms
# set style histogram rowstacked
set boxwidth binwidth * 0.7
set style fill solid 1.0 border -1
# set boxwidth 0.9
# set style fill solid

# settings for plot margins
#set bmargin at screen 0.1
set lmargin at screen 0.09
set rmargin at screen 0.9
set tmargin at screen 0.925
set bmargin at screen 0.18
