reset

# global settings
# font Arial is not installed on uberspace
myFont = "Arial"
myFont = "/usr/share/fonts/dejavu/DejaVuLGCSansMono.ttf"

# settings for data file
set datafile commentschars '#'
set datafile missing '#'
set datafile separator "\t"

# define data filename as variable
data = "stats.dat"
outfilebase = data[0:strlen(data)-4] # removes .dat

# fetch date rage from column 1, since on uberspace gbnuplot is in version 4.2 the commant stats is unavailable
set terminal unknown
plot data u 1:3
year_min = int(GPVAL_DATA_X_MIN)
year_max = int(GPVAL_DATA_X_MAX + 1)
fitLow = GPVAL_DATA_X_MIN 
fitHigh = GPVAL_DATA_X_MAX - 1.0/12 + 0.01 # remove current month, but extend range by a small amount, so that the per-last month is included the range

# define a function that runs perl since Gnuplot V 4.2 does not have the stats command :-(
# does not run in windows, will always return 0.0 :-(
numPointsInRange (datafile, min, max, col) = 0 + system ("perl -e '\
  $c = 0; \
  while ( <> ) { \
  $x = ( split /\t/ )[ 0 ]; \
  $y = ( split /\t/ )[ ".sprintf("%d",col - 1)."]; \
  if (     $x =~ m/^[0-9\.]+$/ \
        and $y =~ m/^[0-9\.]+$/ \
        and $y > 0 \
        and $x >= ".sprintf("%.1f", min)." \
        and $x <= ".sprintf("%.1f", max)." ) \
     {$c++;} \
  }  print $c; \
' < ". datafile)
# print numPointsInRange (data, date_min, fitHigh0, 12)

# settings for terminal 
set terminal png size 800,600 font myFont
# crop 
# set terminal png giant size 3*360,3*180

# settings for plot layout
set grid
# print url to bottom right corner
set label 1 "https://entorb.net/strava" at screen 0.999, screen 0.01 right font myFont.",9"  textcolor rgb "black"

# settings for lines and colors
set style increment user # important!!! switch between linetypes (default) and userdefined linestyles
# set style line  3 linetype -1 linewidth 3 linecolor rgb "black"
set style line  1 linetype 1 linewidth 1 linecolor rgb "dark-green" # box old
set style line  2 linetype 2 linewidth 1 linecolor rgb "light-green" # box new
set style line  9 linetype 9 linewidth 2 linecolor rgb "blue" # percent
set style line  10 linetype 10 linewidth 2 linecolor rgb "gray30" # mean
# TODO: dashtype does not work here 
# set dashtype 2 " - "
# set dashtype 2 (2,4,2,6)

# settings for labels and tics
set title "Strava Äpp Access Stats"
set xlabel "Date" # offset 4,-5
set ylabel "Visitors" offset 1
# set xtics rotate
set ytics nomirror
set y2label "old/new visitors (%)" offset -0.5 textcolor ls 9
set y2tics nomirror textcolor ls 9
set y2tics 25
# set xtics 4
# set mxtics 4 

# settings for key / legend
set key box top left width +0 samplen 2
# reverse invert Left 

# settings for plot range
# set xrange [*:-0.5]
# set yrange [0:*]
set y2range [0:100]

# settings for boxes
set style data histograms
set style histogram rowstacked
# set style boxplot outliers pointtype 7
# set style data boxplot
set boxwidth 1 relative
set style fill solid 1.0 border -1
# set boxwidth 0.9
# set style fill solid

# settings for plot margins
set lmargin at screen 0.1
set rmargin at screen 0.9
set tmargin at screen 0.9
set bmargin at screen 0.1

# settings for fits and ploting of functions
set samples 600

# extract stats data
# not possible on uberspace since there we have Gnuplot 4.2, which misses the stats command
# stats data using 1:3
# set fit quiet # do not print the results in the terminal
av = 0.0
fitav(x) = av
fit [fitLow:fitHigh] fitav(x) data using 1:3 via av 
print av
set label 2 sprintf ("%.1f", av) at graph 0.02, first (av* 1.05) left font myFont.",10" textcolor ls 10

# m0 = 0.0 ; b0 = 0.0
# fit0(x) = x * m0 + b0

# TODO: display the mean only for the relevant range, so exclude fitHigh.
#       this would require not to use the tics from column 2 and to find a way to replace the set style data histograms
set output outfilebase . ".png"
plot \
    data using ($3-$4):xticlabels(2) title "returning" ls 1\
  , data using 4:xticlabels(2) title "new" ls 2 \
  , av title "mean" with lines ls 10 \
  , data using (100*($3-$4)/$3):xticlabels(2) with lines ls 9 axes x1y2 title "%"

# plot \
#   data using 1:3 title "total" with boxes \
#   , data using 1:($3-$4) title "old" with boxes \
#   , data using 1:4 title "new" with boxes \
#   , (x<=fitLow)||(x>=fitHigh)?1/0:av title "mean" with lines ls 1 \
#   , data using 1:(100*($3-$4)/$3) with lines ls 2 axes x1y2 title "%"

unset output

# Cleanup
system ("rm fit.log")
system ("del fit.log")

# experiments
# slopeDuration = 0+6
# set samples 300
# STATS_records=0.0+6
# f(x) = m*x+b
# m=1.0
# b=1.0
# set fit v4
# fit f(x) data using column(0):2 via m,b


# stats data # only working in GP >4.6	
# if (STATS_records>=3) \
#   fit [-slopeDuration:0] f(x) data using 1:2 via m,b
# if (STATS_records>=3) \
#   system(sprintf("echo \"%s\t%.1f\t%.1f\" >>docs/file-monthly-slopes.dat",file,m,b))
# if (STATS_records>=3) \
#   plot data using 1:2 with boxes \
#   , (x<=-slopeDuration)||(x>=-1)?1/0:f(x) with lines lw 4 lc 3 ; \
# else \
#   plot data using 1:2 with boxes
