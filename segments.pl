#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# statistics for my starred segments

# TODO

# IDEAS

# DONE

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

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use lib ( '/var/www/virtual/entorb/perl5/lib/perl5' );
use TMsStrava qw( %o %s);

# at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Starred Segments', 1 );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

say "<p>You can manage your <a href=\"https://www.strava.com/athlete/segments/starred\" target=\"_blank\">starred segments</a> at Strava</p><b>2020-11-17: this feature now requires a paid Strava subscription account :-( </b>";

my @L = TMsStrava::fetchSegmentsStarred( $s{'token'} );

say "<table border=\"1\"><tbody align=\"center\">";
say "<tr>
<th>Type</th>
<th>Name</th>
<th>City</th>
<th>Distance<br/>(km)</th>
<th>Elev delta<br/>(m)</th>
<th>Average Grade</th>
<th>My time<br/>(min)</th>
<th>My speed<br/>(km/h)</th>
<th>My count</th>
</tr>";


# <th>Elev low</th>
# <th>Elev high</th>

foreach my $ref (@L) {
	my %h = %{$ref};
	next if ( not defined $h{"pr_time"} );    # check if I participate on this segment, if not remove from list
	# removed by Strava :-(   my ( $entry_count, $record_time ) = TMsStrava::fetchSegmentRecord( $s{'token'}, $h{"id"} );
	my %h2 = TMsStrava::fetchSegment( $s{'token'}, $h{"id"} );

	# say "<code>";
	# #  say Dumper %h2;
	# say "</code>";
	# say $h{ 'athlete_pr_effort' }{ 'start_date_local' };
	# say $h{ 'athlete_pr_effort' }{ 'id' };
	# say $h2{ 'athlete_segment_stats' }{ 'effort_count' };
	# say $h2{ 'athlete_segment_stats' }{ 'pr_date' };

# removed by Strava
# <th>Athletes</th>
# <th>Record time<br/>(min)</th>
# <th>My rel. time</th>
#   <td>$entry_count</td>
#   <td>" .                                                                                                        ( TMsStrava::secToMinSec($record_time) ) . "</td>


	# my $relTime = ( $h{"pr_time"} > 0 ? $record_time / $h{"pr_time"} : 0 );    # check if I participate on this segment, set time = 0 if not
	say "<tr>
  <td>$h{\"activity_type\"}</td>
  <td><a href=\"https://www.strava.com/segments/" . $h{"id"} . "\" target=\"_blank\">$h{'name'}</td>
  <td>$h{\"state\"}<br/>$h{\"city\"}</td>
  <td>" . ( sprintf "%.1f",   $h{"distance"} / 1000 ) . "</td>
  <td>" . ( sprintf "%d",     $h{"elevation_high"} - $h{"elevation_low"} ) . "</td>
  <td>" . ( sprintf "%.1f%%", $h{"average_grade"} ) . "</td>
  <td><a href=\"https://www.strava.com/segment_efforts/$h{ 'athlete_pr_effort' }{ 'id' }\" target=\"_blank\">" . ( TMsStrava::secToMinSec( $h{"pr_time"} ) ) . "</a><br/><small>" . TMsStrava::formatDate( $h{'athlete_pr_effort'}{'start_date_local'}, 'date' ) . "</small></td>
  <td>" .                                                                                                        ( sprintf( '%.1f', ( $h{"distance"} / 1000 ) / ( $h{"pr_time"} / 3600 ) ) ) . "</td>
  <td>$h2{ 'athlete_segment_stats' }{ 'effort_count' }</td>
  ";
#   <td>
# 	#  <td>$h{\"elevation_low\"}</td>
# 	#  <td>$h{\"elevation_high\"}</td>

# 	if ( $relTime < 0.5 ) {
# 		print '<font color="red">';
# 	} elsif ( $relTime > 0.75 ) {
# 		print '<font color="green">';
# 	}
# 	printf "%d%%", 100 * $relTime;
# 	if ( $relTime < 0.5 or $relTime > 0.75 ) {
# 		print '</font>';
# 	}
# 	say "</td>
  say "</tr>";
} ## end foreach my $ref ( @L )
say "</tbody></table>";

# id 10241952
# name Trimm-Dich-Pfad
# activity_type Run
# distance 1715.3
# pr_time 458
# average_grade 0
# elevation_high 335.9
# elevation_low 308.9

# country Germany
# state Bayern
# city Erlangen
# climb_category 0

# athlete_pr_effort HASH(0x363b048)
# end_latitude 49.606041
# end_latlng ARRAY(0x3689810)
# end_longitude 11.035886
# hazardous 0
# maximum_grade 10.6
# private 0
# resource_state 2
# starred 1
# starred_date 2016-05-10T07:16:02Z
# start_latitude 49.605952
# start_latlng ARRAY(0x335ec58)
# start_longitude 11.036099

# say "<code>";
# foreach my $k ( sort keys %h ) {
#   say "<p>$k\t$h{$k}</p>";
# }
# say "</code>";

TMsStrava::htmlPrintFooter($cgi);
