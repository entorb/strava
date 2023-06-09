#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# display the top 10 activities

# TODO

# IDEAS

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
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
use lib ('/var/www/virtual/entorb/perl5/lib/perl5');
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web"
    ;    # just for making Visual Studio Code happy
# use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;    # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Activity Top10' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

my $year = 'all';
my $type = 'Run';

my %actPerYear;

if ( $cgi->param('type') ) {
  if ( grep { $cgi->param('type') eq $_ } qw (Run Ride) ) {
    $type = $cgi->param('type');
  }
}
if ( $cgi->param('year') ) {
  if ( $cgi->param('year') eq 'all' or $cgi->param('year') =~ m/\d{4}/ ) {
    $year = $cgi->param('year');
  }
}

my @allActivityHashes;
die "E: cache missing" unless ( -f $s{'pathToActivityListHashDump'} );
TMsStrava::logIt("reading activity data from dmp file");
my $ref = retrieve( $s{'pathToActivityListHashDump'} )
    ;    # retrieve data from file (as ref)
@allActivityHashes = @{$ref};    # convert arrayref to array

# first loop through all activities to fetch years
TMsStrava::logIt("first loop through all activities to fetch years");
my %years;
foreach my $ref (@allActivityHashes) {
  my %h        = %{$ref};                   # each $activity is a hashref
  my $date     = $h{'start_date_local'};    # 2016-12-27T14:00:50Z
  my $thisYear = substr( $date, 0, 4 );
  $years{$thisYear}++;
} ## end foreach my $ref (@allActivityHashes)
my @years = sort keys %years;
unshift @years, 'all';
TMsStrava::logIt("done");

say "<form action=\"activityTop10.pl\" method=\"post\">
  <input type=\"hidden\" name=\"session\" value=\"$s{ 'session' }\"/>
  <table border=\"0\">
  <tr><td>Activity Type</td>
  <td>
  <select name=\"type\">
  <option value=\"Run\""
    . ( $type eq 'Run' ? 'selected' : '' ) . ">Run</option>
  <option value=\"Ride\""
    . ( $type eq 'Ride' ? 'selected' : '' ) . ">Ride</option>
  </select>
  </td><td>&nbsp;</td>
  </tr>
  <tr><td>Year</td>
  <td>
  <select name=\"year\">";

foreach my $y (@years) {
  say "<option value=\"$y\""
      . ( $year eq "$y" ? 'selected' : '' )
      . ">$y</option>";
}
say "</select>
  </td>
  <td>
  <input type=\"submit\" name=\"submit\" value=\"Submit\"/>
  </td>
  </tr>
</table>
</form>";

my %database;

foreach my $ref (@allActivityHashes) {
  my %h        = %{$ref};      # each $activity is a hashref
  my $thisType = $h{'type'};

  # filter only relevant activity types
  if ( not $thisType eq $type ) {
    $ref = undef;
    next;
  }

  # filter only relevant years
  my $date     = $h{'start_date_local'};    # 2016-12-27T14:00:50Z
  my $thisYear = substr( $date, 0, 4 );     # YYYY
  if ( $year ne 'all' and $year != $thisYear ) {
    $ref = undef;
    next;
  }

  # add to database hash
  $database{ $h{'id'} } = $ref;
} ## end foreach my $ref (@allActivityHashes)

@allActivityHashes = grep { defined($_) } @allActivityHashes;

# my @rankDisciplines = qw (x_min x_km km/h x_min/km total_elevation_gain x_elev_m/km x_dist_start_end_km average_heartrate);

my %parametersToRank;
$parametersToRank{'x_min'}                = 'Duration (min)';
$parametersToRank{'x_km'}                 = 'Distance (km)';
$parametersToRank{'km/h'}                 = 'Speed (km/h)';
$parametersToRank{'total_elevation_gain'} = 'Elevation Gain (m)';
$parametersToRank{'x_elev_m/km'} = 'Elevation Gain per Distance (m/km)';
$parametersToRank{'x_dist_start_end_km'} = 'Distance Start-End (km)';
$parametersToRank{'average_heartrate'}   = 'Average Heartrate (bpm)';

my @Reihenfolge
    = qw (x_km x_min km/h total_elevation_gain x_elev_m/km x_dist_start_end_km average_heartrate);

say "<p>Jump to<ul>";
foreach my $column (@Reihenfolge) {
  say "<li><a href=#sec_$column>$parametersToRank{ $column }</a></li>";
}
say "</ul></p>";

foreach my $column (@Reihenfolge) {
  die "E: $column is missing in parametersToRank"
      unless defined( $parametersToRank{$column} );
  my $columnTitle = $parametersToRank{$column};
  my @sorted
      = TMsStrava::sortArrayHashRefsNumDesc( $column, @allActivityHashes );

  say "<h3 id=sec_$column>$columnTitle</h3>";
  my $count = 0;
  say '<table width="100%" border="1" cellpadding="2" cellspacing="0">';

  say "<tr><th>Rank</th><th>Date</th><th>Name</th>";
  say "<th>$columnTitle</th>" if ( $column ne 'x_min' and $column ne 'x_km' );
  say "<th>Pace (min/km)"
      if ( $column eq 'km/h' );    # pace only for km/h ranking
  say "<th>Distance<br/>(km)</th><th>Duration (min)</th></tr>";

  foreach my $ref (@sorted) {
    my %h = %{$ref};
    next if ( not defined $h{$column} );
    $count++;
    say "<tr>";
    say "<td>$count</td>";
    say "<td>"
        . TMsStrava::formatDate( $h{'start_date_local'}, 'date' ) . "</td>";
    say "<td>" . TMsStrava::activityUrl( $h{"id"}, $h{"name"} ) . "</td>";
    say "<td>$h{ $column }</td>"
        if ( $column ne 'x_min' and $column ne 'x_km' );
    say "<td>$h{ 'x_min/km' }</td>"
        if ( $column eq 'km/h' );    # pace only for km/h ranking
    say "<td>" . ( sprintf '%.1f', $h{'x_km'} ) . "</td>";
    say "<td>" . ( sprintf '%d',   $h{'x_min'} ) . "</td>";
    say "</tr>";
    last if $count == 25;
  } ## end foreach my $ref (@sorted)
  say "</table>";
} ## end foreach my $column (@Reihenfolge)

TMsStrava::htmlPrintFooter($cgi);
