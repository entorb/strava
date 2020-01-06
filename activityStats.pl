#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# display statistics for cached activities

# TODO
# For the yearly averages 0 values need to be used to fill the gaps
#  this is wrong for pace and other averages!!!
# For the av_all this is wrong!!!

# IDEAS
# * mark record per date bold
# * add record activity value

# DONE
# * add quarter

# Modules: My Default Set
use strict;
use warnings;
use 5.010;    # say
use Data::Dumper;
use utf8;     # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard
use Encode qw(encode decode);

# use File::Path qw/remove_tree/;
use Time::Local;
use Storable;               # read and write variables to
use File::Basename;         # for basename, dirname, fileparse
use File::Copy;
use Cwd;                    # for my $dir = getcwd;

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);                                              # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Activity statistics' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

my $dateresolution = 'Year';                                           # year, month
my $distanceunit   = 'kilometer';                                      # kilometer, mile
my %tableHeaderUnits;
$tableHeaderUnits{'distance'} = 'km';
$tableHeaderUnits{'elev'}     = 'm';
$tableHeaderUnits{'speed'}    = 'km/h';
$tableHeaderUnits{'pace'}     = 'min/km';

my %actPerYear;

if ( $cgi->param('dateresolution') ) {
	if ( grep { $cgi->param('dateresolution') eq $_ } qw (All Year Quarter Month) ) {
		$dateresolution = $cgi->param('dateresolution');
	}
}
if ( $cgi->param('distanceunit') and $cgi->param('distanceunit') eq 'mile' ) {
	$distanceunit                   = 'mile';
	$tableHeaderUnits{'distance'} = 'mi';
	$tableHeaderUnits{'elev'}     = 'ft';
	$tableHeaderUnits{'speed'}    = 'mph';
	$tableHeaderUnits{'pace'}     = 'min/mi';
} ## end if ( $cgi->param( 'distanceunit'...))

say "<h2>Feature ideas?</h2>
<p>Hi folks, I started this app as Excel exporter, but now that I myself use it quite regularly, I find it nice to have the statistics available online without the need to open Excel. 
Do you have ideas for further nice statistics and analytics I should add for all of us having more fun? (based on the data available in the Excel export) 
If so, please drop me a <a href=\"/contact.php?origin=strava\" target=\"_blank\"> message</a>. <br/>
P.S.: If you like this tool, please spread the word ;-)
</p>
<hr/>
";

say "<form action=\"activityStats.pl\" method=\"post\">
  <input type=\"hidden\" name=\"session\" value=\"$s{ 'session' }\"/>
  <table border=\"0\">
  <tr><td>date format</td>
  <td>
  <select name=\"dateresolution\">
  <option value=\"All\" " .     ( $dateresolution eq 'All'     ? 'selected' : '' ) . ">all</option>
  <option value=\"Year\" " .    ( $dateresolution eq 'Year'    ? 'selected' : '' ) . ">year</option>
  <option value=\"Quarter\" " . ( $dateresolution eq 'Quarter' ? 'selected' : '' ) . ">quarter</option>
  <option value=\"Month\" " .   ( $dateresolution eq 'Month'   ? 'selected' : '' ) . ">month</option>
  </select>
  </td><td>&nbsp;</td>
  </tr>
  <tr><td>distance format</td>
  <td>
  <select name=\"distanceunit\">
  <option value=\"kilometer\" " . ( $distanceunit eq 'kilometer' ? 'selected' : '' ) . ">kilometer</option>
  <option value=\"mile\"" .       ( $distanceunit eq 'mile'      ? 'selected' : '' ) . ">mile</option>
  </select>
  </td>
  <td>
  <input type=\"submit\" name=\"submit\" value=\"Submit\"/> 
  </td>
  </tr>
</table>
</form>";

my @allActivityHashes;

die "E: cache missing" unless ( -f $s{'pathToActivityListHashDump'} );

TMsStrava::logIt("reading activity data from dmp file");
my $ref = retrieve( $s{'pathToActivityListHashDump'} );    # retrieve data from file (as ref)
@allActivityHashes = @{$ref};                              # convert arrayref to array

my %database;
my %records;                                                 # per date slice

my $binwidth;                                                # for export file
if ( $dateresolution eq 'Year' ) {
	$binwidth = 1;
} elsif ( $dateresolution eq 'Quarter' ) {
	$binwidth = 1 / 4;
} elsif ( $dateresolution eq 'Month' ) {
	$binwidth = 1 / 12;
}
foreach my $ref (@allActivityHashes) {
	my %h             = %{$ref};                             # each $activity is a hashref
	my $type          = $h{'type'};
	my $date          = $h{'start_date_local'};              # 2016-12-27T14:00:50Z
	my $dateForRecord = substr( $date, 2, 8 );                 # 12-27;
	if ( $dateresolution eq 'Year' ) {
		$date = substr( $date, 0, 4 );                           # YYYY
	} elsif ( $dateresolution eq 'Quarter' ) {

		# $date = substr( $date, 0, 7); # YYYY-MM
		my $y = substr( $date, 0, 4 );
		my $m = substr( $date, 5, 7 );
		if ( $m <= 3 ) {
			$date = "$y-qrt1";
		} elsif ( $m <= 6 ) {
			$date = "$y-qrt2";
		} elsif ( $m <= 9 ) {
			$date = "$y-qrt3";
		} else {
			$date = "$y-qrt4";
		}
	} elsif ( $dateresolution eq 'Month' ) {
		$date = substr( $date, 0, 7 );    # YYYY-MM
	} else {                            # all
		$date = 'all';
	}
	$database{$type}{$date}{'count'}++;
	$database{$type}{$date}{'distance'}             += $h{'distance'};
	$database{$type}{$date}{'moving_time'}          += $h{'moving_time'};
	$database{$type}{$date}{'total_elevation_gain'} += $h{'total_elevation_gain'};

	if ( not exists $records{$type}{$date}{'distance'} or $records{$type}{$date}{'distance'} < $h{'distance'} ) {
		$records{$type}{$date}{'distance'}      = $h{'distance'};
		$records{$type}{$date}{'distance-date'} = $dateForRecord;
		$records{$type}{$date}{'distance-id'}   = $h{'id'};
	}

	if ( not exists $records{$type}{$date}{'moving_time'} or $records{$type}{$date}{'moving_time'} < $h{'moving_time'} ) {
		$records{$type}{$date}{'moving_time'}      = $h{'moving_time'};
		$records{$type}{$date}{'moving_time-date'} = $dateForRecord;
		$records{$type}{$date}{'moving_time-id'}   = $h{'id'};
	}

	if ( not exists $records{$type}{$date}{'total_elevation_gain'} or $records{$type}{$date}{'total_elevation_gain'} < $h{'total_elevation_gain'} ) {
		$records{$type}{$date}{'total_elevation_gain'}      = $h{'total_elevation_gain'};
		$records{$type}{$date}{'total_elevation_gain-date'} = $dateForRecord;
		$records{$type}{$date}{'total_elevation_gain-id'}   = $h{'id'};
	}

	# speed and Hm/km only for dist > 3 km and time > 15 min
	if ( $h{'distance'} > 3000 and $h{'moving_time'} > 900 ) {
		my $kmh = ( ( $h{'distance'} / 1000 ) / ( $h{'moving_time'} / 3600 ) );
		if ( not exists $records{$type}{$date}{'km/h'} or $records{$type}{$date}{'km/h'} < $kmh ) {
			$records{$type}{$date}{'km/h'}      = $kmh;
			$records{$type}{$date}{'km/h-date'} = $dateForRecord;
			$records{$type}{$date}{'km/h-id'}   = $h{'id'};
		}

		# Hm/km
		my $Hmkm = ( $h{'total_elevation_gain'} / ( $h{'distance'} / 1000 ) );
		if ( not exists $records{$type}{$date}{'Hm/km'} or $records{$type}{$date}{'Hm/km'} < $Hmkm ) {
			$records{$type}{$date}{'Hm/km'}      = $Hmkm;
			$records{$type}{$date}{'Hm/km-date'} = $dateForRecord;
			$records{$type}{$date}{'Hm/km-id'}   = $h{'id'};
		}
	} ## end if ( $h{ 'distance' } ...)

} ## end foreach my $ref ( @allActivityHashes)

mkdir $s{'tmpDownloadFolder'} unless -d $s{'tmpDownloadFolder'};

# copy gnuplot templates
for my $file (<gnuplot/act-stats*.gp>) {
	my $fname  = basename $file;
	my $target = "$s{ 'tmpDownloadFolder' }/$fname";

	# copy( $file, $target ) unless ( -f $target ); # TODO:
	copy( $file, $target );
} ## end for my $file ( <gnuplot/act-stats*.gp>)

say "<p>Jump to";
foreach my $type ( sort keys %database ) {    # print navi links
	say " <a href=\"#type$type\">$type</a>";
}
say "</p>";

foreach my $type ( sort keys %database ) {
	say "<h2 id=\"type$type\">$type</h2>";
	say "<table border=\"1\">
  <tr class=\"r0\">
    <th colspan=\"2\">&nbsp;</th>
    <th colspan=\"3\">sum</th>
    <th colspan=\"6\">average</th>
    <th colspan=\"5\">record activities</th>
  </tr>
  <tr class=\"r0\">
  <th>date<br/><small>&nbsp;</small></th>
  <th>count<br/><small>&nbsp;</small></th>
   <th>time<br/><small>(h)</small></th>
    <th>distance<br/><small>($tableHeaderUnits{'distance'})</small></th>
    <th>elev. gain<br/><small>($tableHeaderUnits{'elev'})</small></th>
   <th>time<br/><small>(min)</small></th>
    <th>distance<br/><small>($tableHeaderUnits{'distance'})</small></th>
    <th>elev. gain<br/><small>($tableHeaderUnits{'elev'})</small></th>
    <th>speed<br/><small>($tableHeaderUnits{'speed'})</small></th>
    <th>pace<br/><small>($tableHeaderUnits{'pace'})</small></th>
    <th>elev/dist<br/><small>($tableHeaderUnits{'elev'}/$tableHeaderUnits{'distance'})</small></th>
   <th>time<br/><small>(min)</small></th>
    <th>distance<br/><small>($tableHeaderUnits{'distance'})</small></th>
    <th>elev. gain<br/><small>($tableHeaderUnits{'elev'})</small></th>
    <th>speed<br/><small>($tableHeaderUnits{'speed'})</small></th>
    <th>elev/dist<br/><small>($tableHeaderUnits{'elev'}/$tableHeaderUnits{'distance'})</small></th>
  </tr>";
	my %h      = %{ $database{$type} };
	my $rownum = 0;

	# gen gnuplot data file for Ride and Run
	my $fhOut;
	my $fileOut;
	my @data;    # data for export as .dat
	if ( $dateresolution ne 'All' ) {
		$fileOut = $s{'tmpDownloadFolder'} . "/act-stats-$type-$dateresolution.dat";    # download/<session>/act-stats-Run-Month.dat
		open $fhOut, '>:encoding(UTF-8)', $fileOut or die "ERROR: Can't write to file '$fileOut': $!";
		if ( $distanceunit eq 'kilometer' ) {
			say {$fhOut} "# year_dec\tdate\tcount\ttime (h)\tdistance (km)\telev. gain (m)\ttime (min)\tdistance (km)\telev. gain (m)\tspeed (km/h)\tpace (min/km)\telev/dist (m/km)";
		} else {
			say {$fhOut} "# year_dec\tdate\tcount\ttime (h)\tdistance (mi)\telev. gain (ft)\ttime (min)\tdistance (mi)\telev. gain (ft)\tspeed (mph)\tpace (min/mi)\telev/dist (ft/mi)";
		}
	} ## end if ( $dateresolution ne...)

	my $date_dec_last = 0;
	foreach my $date ( reverse sort keys %h ) {
		$rownum++;
		my $date_dec = 0;
		if ( $dateresolution eq 'Year' ) {
			$date_dec = $date;
		} elsif ( $dateresolution eq 'Quarter' ) {
			my ( $y, $q ) = split '-qrt', $date;
			$date_dec = $y + ( $q - 1 ) / 4;
		} elsif ( $dateresolution eq 'Month' ) {
			my ( $y, $m ) = split '-', $date;
			$date_dec = $y + ( $m - 1 ) / 12;
		}
		my $count       = $database{$type}{$date}{'count'};
		my $time        = $database{$type}{$date}{'moving_time'} / 3600;
		my $dist        = $database{$type}{$date}{'distance'} / 1000;
		my $elev        = $database{$type}{$date}{'total_elevation_gain'};
		my $time_av     = $time * 60 / $count;
		my $dist_av     = $dist / $count;
		my $elev_av     = $elev / $count;
		my $speed_av    = $time > 0 ? $dist / $time : 0;
		my $pace_av     = $dist > 0 ? $time * 60 / $dist : 0;
		my $elevPerDist = $dist > 0 ? $elev / $dist : 0;

		my $rec_time       = $records{$type}{$date}{'moving_time'} / 3600;
		my $rec_time_date  = $records{$type}{$date}{'moving_time-date'};
		my $rec_time_id    = $records{$type}{$date}{'moving_time-id'};
		my $rec_dist       = $records{$type}{$date}{'distance'} / 1000;
		my $rec_dist_date  = $records{$type}{$date}{'distance-date'};
		my $rec_dist_id    = $records{$type}{$date}{'distance-id'};
		my $rec_elev       = $records{$type}{$date}{'total_elevation_gain'};
		my $rec_elev_date  = $records{$type}{$date}{'total_elevation_gain-date'};
		my $rec_elev_id    = $records{$type}{$date}{'total_elevation_gain-id'};
		my $rec_speed      = $records{$type}{$date}{'km/h'};
		my $rec_speed_date = $records{$type}{$date}{'km/h-date'};
		my $rec_speed_id   = $records{$type}{$date}{'km/h-id'};
		my $rec_Hmkm       = $records{$type}{$date}{'Hm/km'};
		my $rec_Hmkm_date  = $records{$type}{$date}{'Hm/km-date'};
		my $rec_Hmkm_id    = $records{$type}{$date}{'Hm/km-id'};

		if ( $distanceunit eq 'mile' ) {
			$dist     /= 1.60934;    # km -> mile
			$speed_av /= 1.60934;    # km -> mile
			$elev        *= 3.28084;              # m -> foot
			$pace_av     *= 1.60934;              # km -> mile
			$elevPerDist *= 3.28084 * 1.60934;    # m/km -> ft/mile
			$rec_dist /= 1.60934;                 # km -> mile
			$rec_elev *= 3.28084;                 # m -> foot
			$rec_speed /= 1.60934;                # km -> mile
			$rec_Hmkm *= 3.28084 * 1.60934;       # m/km -> ft/mile
		} ## end if ( $distanceunit eq ...)

		say "<tr class=\"r" . ( ( $rownum % 2 == 1 ) ? '1' : '2' ) . "\">";    # alternating tr class
		say "  <td>$date</td><td align=\"right\">$count</td>";
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $time;
		printf "  <td align=\"right\">%d</td>\n",                                                                                                                       $dist;
		printf "  <td align=\"right\">%d</td>\n",                                                                                                                       $elev;
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $time_av;
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $dist_av;
		printf "  <td align=\"right\">%d</td>\n",                                                                                                                       $elev_av;
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $speed_av;
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $pace_av;
		printf "  <td align=\"right\">%.1f</td>\n",                                                                                                                     $elevPerDist;
		printf "  <td align=\"right\">%.1f<small> at <a target=\"_blank\" href=\"https://www.strava.com/activities/$rec_time_id\">$rec_time_date</a></small></td>\n",   $rec_time * 60;
		printf "  <td align=\"right\">%.1f<small> at <a target=\"_blank\" href=\"https://www.strava.com/activities/$rec_dist_id\">$rec_dist_date</a></small></td>\n",   $rec_dist;
		printf "  <td align=\"right\">%d<small> at <a target=\"_blank\" href=\"https://www.strava.com/activities/$rec_elev_id\">$rec_elev_date</a></small></td>\n",     $rec_elev;
		printf "  <td align=\"right\">%.1f<small> at <a target=\"_blank\" href=\"https://www.strava.com/activities/$rec_speed_id\">$rec_speed_date</a></small></td>\n", $rec_speed;
		printf "  <td align=\"right\">%.1f<small> at <a target=\"_blank\" href=\"https://www.strava.com/activities/$rec_Hmkm_id\">$rec_Hmkm_date</a></small></td>\n",   $rec_Hmkm;
		say "</tr>";

		if ( $dateresolution ne 'All' ) {

			# if ( $date_dec_last > 0 ) {
			#   # add 0 lines if data missing -> # not a good idea, as this modifies the averages !!!!
			#   while ( $date_dec < $date_dec_last - $binwidth - 0.01 ) {
			#     $date_dec_last -= $binwidth;
			#     # year_dec\tdate\tcount\ttime (h)\tdistance (km)\telev. gain (m)\ttime (min)\tdistance (km)\telev. gain (m)\tspeed (km/h)\tpace (min/km)\telev/dist (m/km)
			#     push @data, sprintf "%.2f\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0", $date_dec_last;    # dist = 0.001 as otherwise elev/dist does run into trouble
			#   }
			# } ## end if ( $date_dec_last > ...)
			my $s = sprintf "%.2f\t$date\t$count", $date_dec;
			$s .= sprintf "\t%.2f\t%.3f", $time, $dist;
			$s .= "\t" . ( $elev > 0 ? sprintf "%.3f", $elev : '0' );
			$s .= sprintf "\t%.3f\t%.3f", $time_av, $dist_av;
			$s .= "\t" . ( $elev_av > 0     ? sprintf "%.3f", $elev_av     : '0' );
			$s .= "\t" . ( $speed_av > 0    ? sprintf "%.3f", $speed_av    : '0' );
			$s .= "\t" . ( $pace_av > 0     ? sprintf "%.3f", $pace_av     : '0' );
			$s .= "\t" . ( $elevPerDist > 0 ? sprintf "%.3f", $elevPerDist : '0' );
			push @data, $s;
		} ## end if ( $dateresolution ne...)
		$date_dec_last = $date_dec;
	} ## end foreach my $date ( reverse ...)
	say "</table>";
	@data = reverse @data;

	# Gnuplot p lotting so far only for Type = Run or Ride
	if ( $dateresolution ne 'All' ) {
		print {$fhOut} join "\n", @data;
		close $fhOut;
		say "<a href=\"$fileOut\">download data</a>";

		# define plot type parameters for gnuplot
		$fileOut = $s{'tmpDownloadFolder'} . "/act-stats-plot-type.gp";
		open $fhOut, '>:encoding(UTF-8)', $fileOut or die "ERROR: Can't write to file '$fileOut': $!";
		say {$fhOut} "activity_type = \"$type\"\ndate_aggregation = \"$dateresolution\"\ndistanceunit = \"$distanceunit\"";
		close $fhOut;

		my $cwd = getcwd;
		chdir $s{'tmpDownloadFolder'};
		`gnuplot act-stats.gp`;
		chdir $cwd;

		say "<p>";
		for my $imgfile (<$s{ 'tmpDownloadFolder' }/act-stats-$type-$dateresolution*.png>) {
			if ( -s $imgfile > 1000 ) {    # min 1000 bytes
				say "<img src=\"$imgfile\" width=\"800\" height=\"400\"><br>";
			}
		}
	} ## end if ( $dateresolution ne...)

} ## end foreach my $type ( sort keys...)
say "</p>";

TMsStrava::htmlPrintFooter($cgi);
