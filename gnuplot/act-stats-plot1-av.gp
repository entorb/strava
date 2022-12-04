# fit average of all data
av_all = -10.0
fitav_all(x) = av_all ;
if (fitHigh0 - date_min > 2 * binwidth) fit [:fitHigh0] fitav_all(x) data using 1:col via av_all

# fit slope of last year ( 4 for aggegation = Year)
b0 = av_all
m0  = 0.1
fit0(x) = m0*x + b0 ;
if (numPointsInRange (data, fitLow0, fitHigh0, col) >= 2) fit [fitLow0:fitHigh0] fit0(x)   data using 1:col via m0, b0
print "0"
# set terminal png
set output outfile . ".png"
# fit average of year -1..-5
av1 = -10 ; fitav1(x) = av1 ;
if (numPointsInRange (data, fitLow1, fitHigh1, col) >= 2) fit [fitLow1:fitHigh1] fitav1(x) data using 1:col via av1
print "1"
av2 = -10 ; fitav2(x) = av2 ;
if (numPointsInRange (data, fitLow2, fitHigh2, col) >= 2) fit [fitLow2:fitHigh2] fitav2(x) data using 1:col via av2
print "2"
av3 = -10 ; fitav3(x) = av3 ;
if (numPointsInRange (data, fitLow3, fitHigh3, col) >= 2) fit [fitLow3:fitHigh3] fitav3(x) data using 1:col via av3
print "3"
av4 = -10 ; fitav4(x) = av4 ;
if (numPointsInRange (data, fitLow4, fitHigh4, col) >= 2) fit [fitLow4:fitHigh4] fitav4(x) data using 1:col via av4
print "4"
av5 = -10 ; fitav5(x) = av5 ;
if (numPointsInRange (data, fitLow5, fitHigh5, col) >= 2) fit [fitLow5:fitHigh5] fitav5(x) data using 1:col via av5
print "5"
plot   \
   data using 1:col with linespoints title "data" \
   , (x<=fitLow0)||(x>=fitHigh0)?1/0:fit0(x) title "slope" with lines ls 2 \
   , (x>=fitHigh0)?1/0:av_all title "mean" with lines ls 3 \
   , (x<=fitLow1)||(x>=fitHigh1)?1/0:av1 notitle with lines ls 4 \
   , (x<=fitLow2)||(x>=fitHigh2)?1/0:av2 notitle with lines ls 4 \
   , (x<=fitLow3)||(x>=fitHigh3)?1/0:av3 notitle with lines ls 4 \
   , (x<=fitLow4)||(x>=fitHigh4)?1/0:av4 notitle with lines ls 4 \
   , (x<=fitLow5)||(x>=fitHigh5)?1/0:av5 notitle with lines ls 4 \

unset output

# svg files are > 100kb :-(
# set terminal svg
# set output outfile . ".svg"
# replot
# unset output
