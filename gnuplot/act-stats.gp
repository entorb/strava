reset

# TODO: use a perl script or something else to get the number of values in the fitrange, if <2 than do not fit


# global settings
# font Arial is not installed on uberspace
#myFont = "Arial"
#myFont = "/usr/share/fonts/dejavu/DejaVuLGCSansMono.ttf"

# settings for data file
set datafile commentschars '#'
set datafile missing '#'
set datafile separator "\t"
# Plot Type
# activity_type = "Run"     # Run Ride
# date_aggregation = "Year" # Year Quarter Month
load "act-stats-plot-type.gp"

# define data filename as variable
data = "act-stats-".activity_type."-".date_aggregation.".dat" # act-stats-run-month.dat
outfilebase = data[0:strlen(data)-4] # removes .dat

# fetch number of data points between min <= x <= max
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


# define variables for fitting
# fetch date rage from column 1, since on uberspace gbnuplot is in version 4.2 the commant stats is unavailable
set terminal unknown
plot data u 1:3
date_min = GPVAL_DATA_X_MIN
date_max = GPVAL_DATA_X_MAX

# year_min = int(date_min)
# year_max = int(date_max + 1)

if (date_aggregation eq "Month")   year_span_for_slope = 1
if (date_aggregation eq "Quarter") year_span_for_slope = 1
if (date_aggregation eq "Year")    year_span_for_slope = 4

if (date_aggregation eq "Month")   binwidth = 1.0/12
if (date_aggregation eq "Quarter") binwidth = 1.0/4
if (date_aggregation eq "Year")    binwidth = 1.0

# do not plot if too little data
if (date_max - date_min < 2 * binwidth) print "W: too few data in datafile ". data ; exit

rangeextender = 0.4 * binwidth # 0.01 # for ensuring that fitHigh is included in fit

# exclude last row from fits (current month/quarter/year)
fitHigh0 = date_max - 1 * binwidth + rangeextender # and extend rage to include pre-last row

# 0 = over year_span_for_slope
fitLow0  = fitHigh0 - year_span_for_slope + binwidth - 2 * rangeextender

# 1 = calendar year ( 4 for date_aggregation=Year)
fitHigh1 = int(fitHigh0) + rangeextender # and extend rage to include pre-last row
fitLow1  = fitHigh1 - year_span_for_slope + binwidth - 2 * rangeextender
fitHigh2 = fitLow1 - binwidth + 2 * rangeextender
fitLow2  = fitHigh2 - year_span_for_slope + binwidth - 2 * rangeextender
fitHigh3 = fitLow2 - binwidth + 2 * rangeextender
fitLow3  = fitHigh3 - year_span_for_slope + binwidth - 2 * rangeextender
fitHigh4 = fitLow3 - binwidth + 2 * rangeextender
fitLow4  = fitHigh4 - year_span_for_slope + binwidth - 2 * rangeextender
fitHigh5 = fitLow4 - binwidth + 2 * rangeextender
fitLow5  = fitHigh5 - year_span_for_slope + binwidth - 2 * rangeextender

if (fitLow0 < date_min) fitLow0 = date_min - 0.4 * binwidth
if (fitLow1 < date_min) fitLow1 = date_min - 0.4 * binwidth
if (fitLow2 < date_min) fitLow2 = date_min - 0.4 * binwidth
if (fitLow3 < date_min) fitLow3 = date_min - 0.4 * binwidth
if (fitLow4 < date_min) fitLow4 = date_min - 0.4 * binwidth
if (fitLow5 < date_min) fitLow5 = date_min - 0.4 * binwidth
if (fitHigh1 < date_min) fitHigh1 = date_min - 0.4 * binwidth
if (fitHigh2 < date_min) fitHigh2 = date_min - 0.4 * binwidth
if (fitHigh3 < date_min) fitHigh3 = date_min - 0.4 * binwidth
if (fitHigh4 < date_min) fitHigh4 = date_min - 0.4 * binwidth
if (fitHigh5 < date_min) fitHigh5 = date_min - 0.4 * binwidth

# print fitHigh0 , fitLow0
# print fitHigh1 , fitLow1
# print fitHigh2 , fitLow2
# print fitHigh3 , fitLow3
# print fitHigh4 , fitLow4
# print fitHigh5 , fitLow5


load "act-stats-layout.gp"


# settings for fits and ploting of functions
set samples 600
FIT_LIMIT = 1e-8 # or even smaller

# do the plotting



col = 3
set title activity_type." ".date_aggregation." Count"
set label 1  "Count"
outfile = outfilebase . "-count"
load "act-stats-plot1-sum.gp"

# exit

col = 4
set title activity_type." ".date_aggregation." Time Sum"
set label 1 "Time (h)"
outfile = outfilebase . "-time-sum"
load "act-stats-plot1-sum.gp"

col = 7
set title activity_type." ".date_aggregation." Time Average"
set label 1 "Time (min)"
outfile = outfilebase . "-time-av"
load "act-stats-plot1-av.gp"

col = 5
set title activity_type." ".date_aggregation." Distance Sum"
if (distanceunit eq "kilometer") \
  set label 1 "Distance (km)"
if (distanceunit eq "mile") \
  set label 1 "Distance (mile)"
outfile = outfilebase . "-distance-sum"
if (activity_type ne "WeightTraining") load "act-stats-plot1-sum.gp"

col = 8
set title activity_type." ".date_aggregation." Distance Average"
if (distanceunit eq "kilometer") \
  set label 1 "Distance (km)"
if (distanceunit eq "mile") \
  set label 1 "Distance (mile)"
outfile = outfilebase . "-distance-av"
if (activity_type ne "WeightTraining") load "act-stats-plot1-av.gp"

col = 6
set title activity_type." ".date_aggregation." Elevation Sum"
if (distanceunit eq "kilometer") \
  set label 1 "Elevation Gain (m)"
if (distanceunit eq "mile") \
  set label 1 "Elevation Gain (ft)"
outfile = outfilebase . "-elevation-sum"
if (activity_type ne "WeightTraining" && activity_type ne "Swim") load "act-stats-plot1-sum.gp"

col = 9
set title activity_type." ".date_aggregation." Elevation Average"
if (distanceunit eq "kilometer") \
  set label 1 "Elevation Gain (m)"
if (distanceunit eq "mile") \
  set label 1 "Elevation Gain (ft)"
outfile = outfilebase . "-elevation-av"
if (activity_type ne "WeightTraining" && activity_type ne "Swim") load "act-stats-plot1-av.gp"

col = 10
set title activity_type." ".date_aggregation." Speed Average"
if (distanceunit eq "kilometer") \
  set label 1 "Speed (km/h)"
if (distanceunit eq "mile") \
  set label 1 "Speed (mph)"
outfile = outfilebase . "-speed-av"
if (activity_type ne "WeightTraining") load "act-stats-plot1-av.gp"

# TODO: replot pace in inverted axis
col = 11
# dummy plot
# ymin = GPVAL_DATA_Y_MIN
# ymax = GPVAL_DATA_Y_MAX
# set output outfile . ".png"
# plot data using 1:col
# unset output
set title activity_type." ".date_aggregation." Pace Average"
if (distanceunit eq "kilometer") \
  set label 1 "Pace (min/km)"
if (distanceunit eq "mile") \
  set label 1 "Pace (min/mi)"
outfile = outfilebase . "-pace-av"
if (activity_type ne "WeightTraining") load "act-stats-plot1-av.gp"
# set yrange [int(ymax):int(ymin)]
# set output outfile . ".png"
# replot
# unset output
# set yrange [0:*]


col = 12
set title activity_type." ".date_aggregation." Elevation/Distance"
if (distanceunit eq "kilometer") \
  set label 1 "Elevation / Distance (m/km)"
if (distanceunit eq "mile") \
  set label 1 "Elevation / Distance (ft/mile)"
outfile = outfilebase . "-elevationPerDistance"
if (activity_type ne "WeightTraining" && activity_type ne "Swim") load "act-stats-plot1-av.gp"

# Cleanup
system ("rm fit.log")
system ("del fit.log")


# experiments
# print STATS_records
# xNumMax = 4
# xmax = STATS_records - 1
# xmin = 0
# if (STATS_records > xNumMax)    xmin = STATS_records - xNumMax
# # xmin = 0
# print xmin

# using stats instead of fits
# stats [fitLow0:fitHigh0] data using 1:col
# stats [fitLow1:fitHigh1] data using 1:col
# av1 = STATS_mean_y
# stats [fitLow2:fitHigh2] data using 1:col
# av2 = STATS_mean_y
# stats [fitLow3:fitHigh3] data using 1:col
# av3 = STATS_mean_y
# stats [fitLow4:fitHigh4] data using 1:col
# av4 = STATS_mean_y
