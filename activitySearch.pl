#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# search for activities
# displays results as list with links to strava

# TODO
# handle miles for distance as well

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
use Time::Local;
use Storable;               # read and write variables to

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use lib ( '/var/www/virtual/entorb/perl5/lib/perl5' );
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);                                              # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Search for Activities' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

# default values for input fields
my $distanceunit = 'km';                                               # kilometer, mile

my %formparam;                                                         # copied from $cgi->param only after checks for invalid chars are OK

# some form param get default values
$formparam{'latitude'}    = 52.518611;                               # Berlin
$formparam{'longitude'}    = 13.408333;                               # Berlin
$formparam{'geoMode'}     = 'start';
$formparam{'city'}        = 'any';
$formparam{'competition'} = '';

# perform checks on form parameters and store as %formparam
# if ( $cgi->param( 'distanceunit' ) and $cgi->param( 'distanceunit' ) eq 'mile' ) {
# $distanceunit = 'mile';
# }
if ( $cgi->param('latitude') and $cgi->param('latitude') =~ m /^[\d+\.]+$/ ) {
	$formparam{'latitude'} = $cgi->param('latitude');
}
if ( $cgi->param('longitude') and $cgi->param('longitude') =~ m /^[\d+\.]+$/ ) {
	$formparam{'longitude'} = $cgi->param('longitude');
}
if ( $cgi->param('maxgeodistance') and $cgi->param('maxgeodistance') =~ m /^[\d+\.]+$/ ) {
	$formparam{'maxgeodistance'} = $cgi->param('maxgeodistance');
}
if ( $cgi->param('geoMode') ) {
	$formparam{'geoMode'} = $cgi->param('geoMode');
}
if ( $cgi->param('actType') ) {
	$formparam{'actType'} = $cgi->param('actType');
}
if ( $cgi->param('yearMin') ) {
	$formparam{'yearMin'} = $cgi->param('yearMin');
}
if ( $cgi->param('yearMax') ) {
	$formparam{'yearMax'} = $cgi->param('yearMax');
}
if ( $cgi->param('city') ) {
	$formparam{'city'} = $cgi->param('city');
}
if ( $cgi->param('maxcitydistance') and $cgi->param('maxcitydistance') =~ m /^[\d+\.]+$/ ) {
	$formparam{'maxcitydistance'} = $cgi->param('maxcitydistance');
}
if ( $cgi->param('distanceMin') and $cgi->param('distanceMin') =~ m /^[\d+\.]+$/ ) {
	$formparam{'distanceMin'} = $cgi->param('distanceMin');
}
if ( $cgi->param('distanceMax') and $cgi->param('distanceMax') =~ m /^[\d+\.]+$/ ) {
	$formparam{'distanceMax'} = $cgi->param('distanceMax');
}
if ( $cgi->param('durationMin') and $cgi->param('durationMin') =~ m /^[\d+\.]+$/ ) {
	$formparam{'durationMin'} = $cgi->param('durationMin');
}
if ( $cgi->param('durationMax') and $cgi->param('durationMax') =~ m /^[\d+\.]+$/ ) {
	$formparam{'durationMax'} = $cgi->param('durationMax');
}
if ( $cgi->param('name') ) {
	$formparam{'name'} = $cgi->param('name');
	$formparam{'name'} =~ s/[^\w ]//g;    # remove non word char
}
if ( $cgi->param('competition') and $cgi->param('competition') =~ m /^\d+$/ ) {
	$formparam{'competition'} = $cgi->param('competition');
}

# read cache to fetch values for filters
my @allActivityHashes;
die "E: cache missing" unless ( -f $s{'pathToActivityListHashDump'} );
TMsStrava::logIt("reading activity data from dmp file");
my $ref = retrieve( $s{'pathToActivityListHashDump'} );    # retrieve data from file (as ref)
@allActivityHashes = @{$ref};                              # convert arrayref to array

my %types;
my %years;
my %cities;

# first loop through all activities to fetch types, years and cities for filter dropdowns
foreach my $ref (@allActivityHashes) {
	my %h    = %{$ref};                                      # each $activity is a hashref
	my $type = $h{'type'};
	my $date = $h{'start_date_local'};                       # 2016-12-27T14:00:50Z
	my $year = substr( $date, 0, 4 );
	$types{$type}++;
	$years{$year}++;
	my $city = $h{'x_nearest_city_start'};
	$cities{$city}++ if ( $city ne '' );
} ## end foreach my $ref ( @allActivityHashes)
my @types = sort keys %types;
unshift @types, 'any';
%types = undef;
my @years = sort keys %years;
unshift @years, 'any';
%years = undef;
my @cities = ();

foreach my $city ( sort keys %cities ) {
	push @cities, "$city ($cities{$city})";
}
unshift @cities, 'any';
%cities = undef;

# display the form
say "<form action=\"activitySearch.pl\" method=\"post\">
  <input type=\"hidden\" name=\"session\" value=\"$s{ 'session' }\"/>";

say "Type
<select name=\"actType\">
";
foreach my $type (@types) {
	say "<option value=\"$type\" " . ( $formparam{'actType'} eq $type ? 'selected' : '' ) . ">$type</option>";
}
say " </select><br/>";

say "Competition/race<input type=\"checkbox\" name=\"competition\" value=\"1\"" . ( $formparam{'competition'} == 1 ? ' checked' : '' ) . "><br/>";

say "Date range
<select name=\"yearMin\">
";
foreach my $year (@years) {
	say "<option value=\"$year\" " . ( $formparam{'yearMin'} eq $year ? 'selected' : '' ) . ">$year</option>";
}
say " </select>";
say " - ";
say "<select name=\"yearMax\">
";
foreach my $year (@years) {
	say "<option value=\"$year\" " . ( $formparam{'yearMax'} eq $year ? 'selected' : '' ) . ">$year</option>";
}
say " </select><br/>";

say "Duration
<input type=\"number\" id=\"durationMin\" name=\"durationMin\" style=\"width: 40px\" placeholder=\"0.2\" min=\"0\" max=\"72\" value=\"" . $formparam{'durationMin'} . "\" step=\"0.1\">
 -
<input type=\"number\" id=\"durationMax\" name=\"durationMax\" style=\"width: 40px\" placeholder=\"1.5\" min=\"0\" max=\"72\" value=\"" . $formparam{'durationMax'} . "\" step=\"0.1\">
hours<br/>";

say "Distance
<input type=\"number\" id=\"distanceMin\" name=\"distanceMin\" style=\"width: 40px\" placeholder=\"5\" min=\"0\" max=\"999\" value=\"" . $formparam{'distanceMin'} . "\" step=\"1\">
 -
<input type=\"number\" id=\"distanceMax\" name=\"distanceMax\" style=\"width: 40px\" placeholder=\"10\" min=\"0\" max=\"999\" value=\"" . $formparam{'distanceMax'} . "\" step=\"1\">
km<br/>";

say "Name
<input name=\"name\" value=\"$formparam{ 'name'}\"/>
<br/>
";

say "Nearest city (start)
<select name=\"city\">";
foreach my $thisCity (@cities) {
	say "<option value=\"$thisCity\" " . ( $formparam{'city'} eq $thisCity ? 'selected' : '' ) . ">$thisCity</option>";
}
say "</select>
plus
<input type=\"number\" id=\"maxcitydistance\" name=\"maxcitydistance\" style=\"width: 40px\" placeholder=\"3\" min=\"0\" max=\"999\" value=\"" . $formparam{'maxcitydistance'} . "\" step=\"1\">
km <br/>";

say "Distance to gps
<select name=\"geoMode\">
  <option value=\"start\" " . ( $formparam{'geoMode'} eq 'start' ? 'selected' : '' ) . ">start</option>
  <option value=\"end\"" .    ( $formparam{'geoMode'} eq 'end'   ? 'selected' : '' ) . ">end</option>
  <option value=\"both\"" .   ( $formparam{'geoMode'} eq 'both'  ? 'selected' : '' ) . ">start or end</option>
</select>
at max
<input type=\"number\" id=\"maxgeodistance\" name=\"maxgeodistance\" style=\"width: 40px\" placeholder=\"3\" min=\"0\" max=\"999\" value=\"" . $formparam{'maxgeodistance'} . "\" step=\"1\">
km " .

  # <select name=\"distanceunit\">
  # <option value=\"kilometer\" " . ( $distanceunit eq 'km'   ? 'selected' : '' ) . ">km</option>
  # <option value=\"mile\"" .       ( $distanceunit eq 'mile' ? 'selected' : '' ) . ">mile</option>
  # </select>
  "to lat, long:
<input type=\"number\" id=\"latitude\" name=\"latitude\" style=\"width: 70px\" placeholder=\"52.518611\" value=\"" . $formparam{'latitude'} . "\" step=\"any\">
,
<input type=\"number\" id=\"longitude\" name=\"longitude\" style=\"width: 70px\" placeholder=\"13.408333\" value=\"" . $formparam{'longitude'} . "\" step=\"any\">
<br/>
<input type=\"submit\" name=\"submit\" value=\"Submit\"/>
</form>";

# form was submitted, so the search is performed
if ( $cgi->param('submit') ) {
	my $maxgeodistance_km = $formparam{'maxgeodistance'};
	$maxgeodistance_km *= 1.60934 if $distanceunit eq "mile";    # km -> mile
	$formparam{'city'} =~ s/ \(\d+\)$//;                       # remove count EU-AT-7-Koessen (5)

	# Search for nearest city
	if ( $formparam{'maxcitydistance'} > 0 ) {

		# Form: EU-AT-7-Koessen
		# File: EU,AT,7,Koessen,47.6699,12.4055
		my $s = $formparam{'city'};
		$s =~ s/^([^\-]{2})\-([^\-]{2})\-([^\-]+)\-/$1,$2,$3,/;
		my $fileIn = $o{'cityGeoDatabase'};
		open my $fhIn, '<:encoding(UTF-8)', $fileIn or die "ERROR: Can't read from file '$fileIn': $!";
		while ( my $line = <$fhIn> ) {
			next if $line =~ m/^#/;
			if ( $line =~ m/$s.*/ ) {
				@_ = split ",", $line;
				$formparam{'maxcitylatitude'} = $_[4];
				$formparam{'maxcitylongitude'} = $_[5];
				last;
			} ## end if ( $line =~ m/$s.*/ )
		} ## end while ( my $line = <$fhIn>)
		close $fhIn;
	} ## end if ( $formparam{ 'maxcitydistance'...})

	# print header of results table
	say '<table width="100%" border="1" cellpadding="2" cellspacing="0">';
	say '<tr><th>Type</th><th>Date</th><th>Name</th><th>Duration</th><th>Distance</th></tr>';
	foreach my $ref (@allActivityHashes) {
		my %h    = %{$ref};                   # each $activity is a hashref
		my $date = $h{'start_date_local'};    # 2016-12-27T14:00:50Z
		$date = substr( $date, 0, 10 );
		my $thisActYear = substr( $date, 0, 4 );
		$thisActYear += 0;                      # make numeric

		if ( $formparam{'actType'} ne 'any' ) {
			next unless $h{'type'} eq $formparam{'actType'};
		}
		if ( $formparam{'competition'} == 1 ) {    # run: 1 = race, ride: 11 = race
			next
			  unless ( ( $h{'type'} eq 'Run' and $h{'workout_type'} == 1 )
				or ( $h{'type'} eq 'Ride' and $h{'workout_type'} == 11 ) );
		}
		if ( $formparam{'yearMin'} ne 'any' ) {
			next unless $thisActYear >= $formparam{'yearMin'};
		}
		if ( $formparam{'yearMax'} ne 'any' ) {
			next unless $thisActYear <= $formparam{'yearMax'};
		}
		if ( $formparam{'durationMin'} > 0 ) {
			next unless $h{'moving_time'} / 3600 >= $formparam{'durationMin'};
		}
		if ( $formparam{'durationMax'} > 0 ) {
			next unless $h{'moving_time'} / 3600 <= $formparam{'durationMax'};
		}
		if ( $formparam{'distanceMin'} > 0 ) {
			next unless $h{'distance'} / 1000 >= $formparam{'distanceMin'};
		}
		if ( $formparam{'distanceMax'} > 0 ) {
			next unless $h{'distance'} / 1000 <= $formparam{'distanceMax'};
		}

		if ( $formparam{'name'} ne '' ) {
			$formparam{'name'} = "\L$formparam{ 'name' }";    # lowercase
			 #      print $formparam{ 'name' };
			next unless "\L$h{ 'name' }" =~ m/$formparam{ 'name' }/;
		}

		if ( $formparam{'city'} ne 'any' ) {
			if ( $formparam{'maxcitydistance'} == 0 ) {
				next unless $h{'x_nearest_city_start'} eq $formparam{'city'};
			} else {
				next if not defined $h{'start_latlng'};
				my @a = @{ $h{'start_latlng'} };

				# fetched city coord from data file
				my @b    = ( $formparam{'maxcitylatitude'}, $formparam{'maxcitylongitude'} );
				my $dist = TMsStrava::geoDistance( $a[0], $a[1], $b[0], $b[1] );
				next unless $dist <= $formparam{'maxcitydistance'};
			} ## end else [ if ( $formparam{ 'maxcitydistance'...})]
		} ## end if ( $formparam{ 'city'...})

		# filter by geo dist, only if set
		if ( $formparam{'maxgeodistance'} > 0 ) {
			my $dist = 99999;
			if ( defined $h{'start_latlng'} and ( $formparam{'geoMode'} eq 'start' or $formparam{'geoMode'} eq 'both' ) ) {
				my @a         = @{ $h{'start_latlng'} };
				my $distStart = TMsStrava::geoDistance( $a[0], $a[1], $formparam{'latitude'}, $formparam{'longitude'} );
				$dist = $distStart;
			}
			if ( defined $h{'end_latlng'} and ( $formparam{'geoMode'} eq 'end' or $formparam{'geoMode'} eq 'both' ) ) {
				my @a       = @{ $h{'end_latlng'} };
				my $distEnd = TMsStrava::geoDistance( $a[0], $a[1], $formparam{'latitude'}, $formparam{'longitude'} );
				$dist = $distEnd if ( $distEnd < $dist );
			}
			next if ( $dist == 99999 );               # no dist calculate-able
			next if ( $dist > $maxgeodistance_km );
		} ## end if ( $formparam{ 'maxgeodistance'...})

		# print if above filters match
		say " <td>$h{'type'}</td>";
		say " <td>$date</td>";
		say " <td>" . TMsStrava::activityUrl( $h{"id"}, $h{"name"} ) . "</td>";
		say sprintf " <td>" . TMsStrava::secToMinSec( $h{"moving_time"} ) . "</td>";
		say sprintf " <td>%.1f</td>", $h{'distance'} / 1000;
		say "</tr>";
	} ## end foreach my $ref ( @allActivityHashes)
	say "</table>";
} ## end if ( $cgi->param( 'submit'...))

TMsStrava::htmlPrintFooter($cgi);
