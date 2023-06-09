#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Generates ics calender of cached activities

# TODO

# IDEAS

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
# use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT
use autodie qw (open close)
    ;    # Replace functions with ones that succeed or die: e.g. close

use lib ('/var/www/virtual/entorb/perl5/lib/perl5');

# Modules: Perl Standard
use Storable;          # read and write variables to filesystem
use File::Basename;    # for basename, dirname, fileparse
use File::Path qw(make_path);
use Date::Parse;
# use DateTime; # not working on uberspace, could not fix it, so tried POSIX instead
use POSIX qw(strftime);

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
# use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
# use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;    # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Export activity calendar' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

# if not already done, fetchActivityList, 200 per page into dir activityList
unless ( -f $s{'pathToActivityListHashDump'} ) {
  die("E: activity cache missing");
}

TMsStrava::logIt("reading activity data from dmp file");
my $ref = retrieve( $s{'pathToActivityListHashDump'} )
    ;    # retrieve data from file (as ref)
my @allActivityHashes = @{$ref};    # convert arrayref to array

my $pathToICS = "$s{'tmpDownloadFolder'}/ActivityList.ics";

# Generate Excel only if not already done
unless ( -f $pathToICS ) {
  my $ics_header = "BEGIN:VCALENDAR
CALSCALE:GREGORIAN
VERSION:2.0
X-WR-CALNAME:Strava Activity Export by entorb.net
METHOD:PUBLISH
";
  my $ics_footer = "END:VCALENDAR
";

  # V1: DateTime
  # my $date_str_now = DateTime->now()->iso8601().'Z';
  # $date_str_now =~ s/[\-:]//g;
  # V2: POSIX
  # my $now = time();
  my $date_str_now = strftime( '%Y%m%dT%H%M%SZ', gmtime( time() ) );

  open my $fhOut, '>:encoding(UTF-8)', $pathToICS
      or die "ERROR: Can't write to file '$pathToICS': $!";
  print {$fhOut} $ics_header;

  foreach my $activity (@allActivityHashes) {
    my %h = %{$activity};    # each $activity is a hashref

    foreach my $k ( sort keys %h ) {
      # say "$k\t$h{$k}";
    }
    # say $h{'id'};
    # say $h{'type'};
    # say $h{'name'};
    # say $h{'start_date'};
    # say $h{'elapsed_time'};
    next if ( $h{'elapsed_time'} < 5 * 60 );

    my $ts = str2time( $h{'start_date'} );    # from Date::Parse

    my $end_date
        = strftime( '%Y%m%dT%H%M%SZ', gmtime( $ts + $h{'elapsed_time'} ) );
    # say $end_date;
    my $start_date = $h{'start_date'};
    $start_date =~ s/[\-:]//g;

    my $location = "unknown";
    if ( exists $h{'x_nearest_city_start'} ) {
      $location = $h{'x_nearest_city_start'};
    }
    else {
      my @L = ();
      push @L, $h{'location_city'}    if $h{'location_city'};
      push @L, $h{'location_state'}   if $h{'location_state'};
      push @L, $h{'location_country'} if $h{'location_country'};
      if (@L) {
        $location = join( ", ", @L );
      }
    } ## end else [ if ( exists $h{'x_nearest_city_start'...})]
    my $vevent = "BEGIN:VEVENT
UID:strava-id-$h{'id'}
TRANSP:OPAQUE
DTSTART:$start_date
DTEND:$end_date
CREATED:$end_date
LAST-MODIFIED:$date_str_now
DTSTAMP:$date_str_now
SUMMARY:$h{'type'}: $h{'name'} (Strava)
LOCATION:$location
URL;VALUE=URI:https://www.strava.com/activities/$h{'id'}
DESCRIPTION:open at Strava: https://www.strava.com/activities/$h{'id'}\\n\\ngenerated via https://entorb.net/strava/
SEQUENCE:0
END:VEVENT
";
# FIXME: SEQUENCE is the revision number of the event and should be increase when creating a new one
    print {$fhOut} $vevent;
    #    last;
  } ## end foreach my $activity (@allActivityHashes)
  print {$fhOut} $ics_footer;
  close $fhOut;

} ## end unless ( -f $pathToICS )
say
    "<p>This feature generates a calender of your cached activities in .ics format. This file can be imported into you calender application. I suggest using a new separate Strava calender than can easily be dropped completely if you do not like the result.</p>";

say "Download: <a href=\"$pathToICS\">your activity calendar</a>";

TMsStrava::htmlPrintFooter($cgi);
