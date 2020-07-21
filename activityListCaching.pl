#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# perform download and caching of the activitiy list
# 2 modes: all activities, or single year
# calculates some additional fields per activity e.g. km/h

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
use Time::Local;
use Storable;               # read and write variables to
use File::Basename;         # for basename, dirname, fileparse
use File::Path qw(make_path);

use local::lib;
use JSON::Create 'create_json';

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ( '.' );
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);                                              # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Activity List Caching' );
TMsStrava::initSessionVariables( $cgi->param( "session" ) );
TMsStrava::logIt( "#\n# Start file file: Activity List Caching\n#" );

my $yearToDL = '';                                                     # all or year
if ( $cgi->param( 'year' ) ) {
  $yearToDL = $cgi->param( 'year' );
}
my $allStartPage = 1;                                                  # if mode = all, the first page to fetch
if ( $cgi->param( 'allStartPage' ) ) {
  $allStartPage = $cgi->param( 'allStartPage' );
}
my $dlActivitiesPerPage = 200;                                         # Strava has a max of 200 per page
my @allActivityHashes   = ();
my %actPerYear;
my $allLastPageReached = 0;

# read already cached activities
if ( -f $s{ 'pathToActivityListHashDump' } ) {

  # if ( $#allActivityHashes == -1 ) {
  @allActivityHashes = @{ retrieve( $s{ 'pathToActivityListHashDump' } ) };    # retrieve data from file (as ref)
}

if ( $yearToDL ne '' ) {                                                       # all or a certain year -> perform some download
  #
  # DL Mode All
  #
  if ( $yearToDL eq 'all' ) {

    # if page = 1 -> delete all cache files
    if ( $allStartPage == 1 ) {
      TMsStrava::clearCache();    # clear cache only at first DL page of DL Mode all
      @allActivityHashes = ();
    }

    # download data for all years
    $allLastPageReached = TMsStrava::fetchActivityList( $s{ 'token' }, $dlActivitiesPerPage, 0, $allStartPage, 5 );

    # max 200 per page/json file
    # max 0 days past
    # start at page=1
    # numpages=5 -> 1000 activities
    my @listOfNewFiles = ();
    for ( my $i = $allStartPage; $i < $allStartPage + 5; $i++ ) {
      $_ = sprintf "$s{'tmpDataFolder'}/activityList/all_per-page-" . $dlActivitiesPerPage . "_page-%05d.json", $i;
      if ( not -f $_ ) {
        last;
      } else {
        push @listOfNewFiles, $_;
      }
    } ## end for ( my $i = $allStartPage...)

    if ( $allLastPageReached == 0 ) {
      $allStartPage += 5;
    }

    # recreate hash cache
    # my @L = <$s{'tmpDataFolder'}/activityList/all_*.json>;
    # prepend newly downloaded files
    unshift @allActivityHashes, reverse TMsStrava::convertJsonFilesToArrayOfHashes( @listOfNewFiles );    # reverse -> ASC sorting

    #
    # DL Mode Single Year
    #
  } elsif ( $yearToDL >= 1950 ) {

    # delete old files for this year if present
    $_ = "$s{'tmpDataFolder'}/activityList/" . $yearToDL . "_";
    unlink foreach ( <$_*.json> );

    # delete old all year files if present
    unlink foreach ( <$s{'tmpDataFolder'}/activityList/all_*.json> );

    # delete old excel file if present
    unlink foreach ( <$s{'tmpDataFolder'}/activityList/*.xlsx> );

    # delete old zip file if present
    unlink foreach ( <$s{'tmpDataFolder'}/activityList/*.zip> );

    # delete hash cache
    unlink foreach ( <$s{'tmpDataFolder'}/activityList/*.dmp> );

    # download data for selected year
    TMsStrava::fetchActivityListYear( $s{ 'token' }, $dlActivitiesPerPage, $yearToDL );

    # recreate/overwrite activity list hash cache, read all json files in the folder
    # Ordering problem: api gives latest activity first per call, but fetching several years messes the order, if each year-file is in reverse order.
    # Solution: fetch files sorted by year, starting with the latest
    # and do a complete refresh of allActivityHashes, not only the new files :-(
    @_ = localtime time;
    my $year = $_[ 5 ] + 1900;
    my @L;    # list of activity json files, sorted in correct order
    while ( $year >= 1950 ) {
      $_ = "$s{'tmpDataFolder'}/activityList/" . $year . "_";
      push @L, <$_*.json>;
      $year--;
    }
    @allActivityHashes = reverse TMsStrava::convertJsonFilesToArrayOfHashes( @L );    # reverse -> ASC sorting
  } ## end elsif ( $yearToDL >= 1950)

  my %gear;
  if ( -f $s{ 'pathToGearHashDump' } ) {
    %gear = %{ retrieve( $s{ 'pathToGearHashDump' } ) };                              # retrieve data from file (as ref)
  }

  # in this hash a database of cityname and coordinates is stored: $latitude, $longitude, $name
  my %geoBoxes = TMsStrava::geoBoxesFromDataFile( $o{ 'cityGeoDatabase' } );
  my %geoCache;                                                                       # a cache of lat,lon -> name
  my @knownLocations = TMsStrava::getKnownLocationsOfUser();
  my %knownLocationsCache;                                                            # A cache of lat,lon -> id

  # walk through all activities
  # calculate x_ fields for new activities
  # check for gear_id and fetch gear_name if not already cached
  # calculate nearest city based on DB
  # idea: use caching in hash dump as well?
  foreach my $activity ( @allActivityHashes ) {
    my %h = %{ $activity };    # each $activity is a hashref
    # next if already modified this activity in the cache earlier
    if ( exists $h{ 'x_start_h' } ) {
      next;
    }

    $h{ "x_url" } = "https://www.strava.com/activities/" . $h{ "id" };

    # add calculated fields
    if ( $h{ "start_date_local" } and $h{ "start_date_local" } =~ m/(\d+)\-(\d+)\-(\d+)T(\d+):(\d+):(\d+)/ ) {

      # 2018-10-02T08:10:49Z
      $h{ "x_start_h" } = sprintf "%.1f", $4 + $5 / 60 + $6 / 3600;
      $h{ "x_date" }    = "$1-$2-$3";
    } ## end if ( $h{ "start_date_local"...})
    if ( $h{ "average_speed" } and $h{ "average_speed" } > 0 ) {
      $h{ "x_min/km" }   = sprintf "%.2f", 1 / $h{ "average_speed" } / 60 * 1000;    # m/s -> min/km = 1 / X / 60 * 1000
      $h{ "km/h" }       = sprintf "%.2f", $h{ "average_speed" } * 3.6;              # m/s -> km/h   = X * 3,6
      $h{ "x_max_km/h" } = sprintf "%.2f", $h{ "max_speed" } * 3.6;
    }
    if ( $h{ "moving_time" } ) {
      $h{ "x_min" } = sprintf "%.1f", $h{ "moving_time" } / 60;
    }
    if ( $h{ "distance" } ) {
      $h{ "x_km" } = sprintf "%.3f", $h{ "distance" } / 1000;
      $h{ "x_mi" } = sprintf "%.3f", $h{ "distance" } / 1000 / 1.60934;              # km -> mile
      if ( $h{ "average_speed" } and $h{ "average_speed" } > 0 ) {
        $h{ "x_min/mi" }  = sprintf "%.2f", 1 / $h{ "average_speed" } / 60 * 1000 * 1.60934;
        $h{ "x_mph" }     = sprintf "%.2f", $h{ "average_speed" } * 3.6 / 1.60934;
        $h{ "x_max_mph" } = sprintf "%.2f", $h{ "max_speed" } * 3.6 / 1.60934;
      }
      if ( $h{ 'total_elevation_gain' } ) {
        $h{ 'x_elev_m/km' } = sprintf "%.2f", $h{ 'total_elevation_gain' } / $h{ "x_km" };
        $h{ 'x_elev_%' }    = sprintf "%.2f", $h{ 'total_elevation_gain' } / $h{ "x_km" } / 10;
      }
    } ## end if ( $h{ "distance" } )

    # gear
    if ( exists $h{ 'gear_id' } and $h{ 'gear_id' } ne '' ) {

      # fetch gear_name if not already cached
      if ( not exists $gear{ $h{ 'gear_id' } } ) {
        $gear{ $h{ 'gear_id' } } = TMsStrava::fetchGearName( $s{ 'token' }, $h{ 'gear_id' } );
      }
      $h{ 'x_gear_name' } = $gear{ $h{ 'gear_id' } };
    } ## end if ( exists $h{ 'gear_id'...})

    # geo: search for closest city to the start of the activity
    # stored as x_nearest_city_start
    if ( exists( $h{ 'start_latlng' } ) and ref( $h{ 'start_latlng' } ) eq 'ARRAY' ) {
      my ( $latitude, $logitude ) = @{ $h{ 'start_latlng' } };

      # dist start - end
      # stored as x_dist_start_end_km
      if ( exists( $h{ 'end_latlng' } ) ) {
        $h{ 'x_dist_start_end_km' } = sprintf '%.1f', TMsStrava::geoDistance( @{ $h{ 'start_latlng' } }, @{ $h{ 'end_latlng' } } );
      }
      my ( $cityName, $cityDist );
      if ( exists $geoCache{ "$latitude,$logitude" } ) {    # already in cache
        $cityName = $geoCache{ "$latitude,$logitude" };

        # say "<p>cache: $cityName</p>";
      } else {                                              # not in cache, so calculate nearest city
        ( $cityName, $cityDist ) = TMsStrava::geoBoxesFetchClosestEntry( \%geoBoxes, $latitude, $logitude );
        $geoCache{ "$latitude,$logitude" } = $cityName;

        # say "found: $cityName<br>";
      } ## end else [ if ( exists $geoCache{...})]
      $h{ 'x_nearest_city_start' } = $cityName if ( $cityName ne 'none' );
    } ## end if ( exists( $h{ 'start_latlng'...}))

    # check if start/stop is a known location (distance to known location < 750m)
    for my $start_end ( 'start', 'end' ) {                  # for $h{"start_latlng"} and so on
      my $foundLoc  = "none";
      my $foundDist = 999;
      if ( ref( $h{ $start_end . "_latlng" } ) eq "ARRAY" ) {
        my ( $lat, $lng ) = @{ $h{ $start_end . "_latlng" } };
        if ( exists $knownLocationsCache{ "$lat, $lng" } ) {
          $foundLoc = $knownLocationsCache{ "$lat, $lng" };

          # say "<p>cache: $foundLoc</p>";

        } else {
          foreach my $locationLine ( @knownLocations ) {
            my ( $locationLat, $locationLng, $locationName ) = @{ $locationLine };

            # my ($locationLat, $locationLng, $locationName) = split " ", $locationLine;
            my $distance = TMsStrava::geoDistance( $lat, $lng, $locationLat, $locationLng );

            # say sprintf "Distance to $locationName\t=\t%.1f km<br>", $distance;
            if ( $distance < 0.75 and $distance < $foundDist ) {
              $foundLoc  = $locationName;
              $foundDist = $distance;
            }
          }    # foreach my $locationLine
          $knownLocationsCache{ "$lat, $lng" } = $foundLoc;
        } ## end else [ if ( exists $knownLocationsCache...)]
        if ( $foundLoc ne 'none' ) {
          $h{ 'x_' . $start_end . "_locality" } = $foundLoc;
        }
      }    # if ref($h{$start_end."_latlng"}) eq "ARRAY"
    }    # for my $start_end ('start','end')

    # update the activity in the hash of activities
    $activity = \%h;    # add new hash field
  } ## end foreach my $activity ( @allActivityHashes)

  # write ActivityHash and geadHash to filesystem for caching
  store \@allActivityHashes, $s{ 'pathToActivityListHashDump' };

  my $dir = dirname( $s{ 'pathToActivityListJsonDump' } );
  make_path $dir unless -d $dir;

  open my $fhOut, '>:encoding(UTF-8)', $s{ 'pathToActivityListJsonDump' } or die "ERROR: Can't write to file '" . $s{ 'pathToActivityListJsonDump' } . "': $!";
  print { $fhOut } create_json( \@allActivityHashes );
  close $fhOut;

  store \%gear, $s{ 'pathToGearHashDump' };
} ## end if ( $yearToDL ne '' )

TMsStrava::htmlPrintNavigation();

# walk through all activities to count the number of activities per year
foreach my $activity ( @allActivityHashes ) {
  my %h                = %{ $activity };              # each $activity is a hashref
  my $start_date_local = $h{ 'start_date_local' };    # 2016-12-27T14:00:50Z
  $start_date_local =~ m/^(\d{4})\-/;
  $actPerYear{ $1 }++;
} ## end foreach my $activity ( @allActivityHashes)

# if DL mode = all and not $allLastPageReached, than print a form for download next 1000 activities
if ( $yearToDL eq 'all' and $allLastPageReached == 0 ) {
  say '<form action="activityListCaching.pl" method="post">
  <input type="hidden" name="session" value="' . $s{ 'session' } . '"/>
  <input type="hidden" name="year" value="all"/>
  <input type="hidden" name="allStartPage" value="' . $allStartPage . '"/>
  Max number of 1000 activities reached. Press 
  <input type="submit" name=allnext1000" id="allnext1000" value="Next 1000">
  to cache the next 1000 activities.
  </form>';
} ## end if ( $yearToDL eq 'all'...)

# say "<h1>Cache of activity list</h1>";

# Display cache contents
# no form if all activities have been downloaded
my $allActivitiesCached = 0;
@_                   = <$s{'tmpDataFolder'}/activityList/all_*.json>;
$allActivitiesCached = 1 if ( $#_ >= 0 );

if ( $allActivitiesCached == 0 ) {
  say '
  <form action="activityListCaching.pl" method="post">
  <input type="hidden" name="session" value="' . $s{ 'session' } . '"/>';
}
say '<table border="1">
<tr><th>Year</th><th>Activities</th></tr>';
@_ = localtime time;

# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
my $year = $_[ 5 ] + 1900;
while ( $year >= 2000 ) {    # here 2000 as well
  # $_ = "$s{'tmpDataFolder'}/activityList/".$year."_";
  # my @L = <$_*.json>;
  # my $numFiles = 1 + $#L;
  say '<tr><td>';
  if ( $allActivitiesCached == 0 ) {
    say "<input type=\"submit\" name=\"year\" id=\"btnDlYear$year\" value=\"$year\">";
  } else {
    say $year;
  }
  say "</td><td>$actPerYear{$year}</td></tr>";
  $year--;
} ## end while ( $year >= 2000 )
say '</table>';
say '</form>' if ( $allActivitiesCached == 0 );

TMsStrava::htmlPrintFooter( $cgi );
