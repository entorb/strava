#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Display a list of cached activities

# TODO

# IDEAS
# limit number of pages to download/display?
# display only 200 per page, and add link to next page?

# DONE
# Zipping source jsons

# Modules: My Default Set
use strict;
use warnings;
use 5.010;    # say
use Data::Dumper;
use utf8;     # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard
use Storable;               # read and write variables to filesystem
use File::Basename;         # for basename, dirname, fileparse
use File::Path qw(make_path);

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ( '.' );
use lib ( '/var/www/virtual/entorb/perl5/lib/perl5' );
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);                                              # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'List of activities' );
TMsStrava::initSessionVariables( $cgi->param( "session" ) );
TMsStrava::htmlPrintNavigation();

# if not already done, fetchActivityList, 200 per page into dir activityList
unless ( -f $s{ 'pathToActivityListHashDump' } ) {
  die( "E: activity cache missing" );
}

TMsStrava::logIt( "reading activity data from dmp file" );
my $ref               = retrieve( $s{ 'pathToActivityListHashDump' } );    # retrieve data from file (as ref)
my @allActivityHashes = @{ $ref };                                         # convert arrayref to array

my $pathToZip = "$s{'tmpDownloadFolder'}/ActivityList.zip";

# zip jsons if not already done
unless ( -f $pathToZip ) {
  my $dir = dirname( $pathToZip );
  make_path $dir unless -d $dir;
  undef $dir;
  my @L = <$s{'tmpDataFolder'}/activityList/*.json>;
  TMsStrava::zipFiles( $pathToZip, @L );
} ## end unless ( -f $pathToZip )

say "<p>Download your data as <a href=\"$pathToZip\">zipped .json files</a></p>";

say '
<form action="activityModify.pl?session=' . $s{ 'session' } . '" method="post">
<input type="hidden" name="session" value="' . $s{ 'session' } . '"/>
<table width="100%" border="1" cellpadding="2" cellspacing="0">
<input type="submit" name="submitFromActivityList" value="Edit selected"/>
<tr>
<th>&nbsp;</th><th>Type</th><th>Date</th><th>Name</th><th>Minutes</th><th>Commute</th><th>Training Machine</th><th>Visibility</th>
</tr>
';
my $rownum = 0;
foreach my $activity ( @allActivityHashes ) {
  $rownum++;
  my %h = %{ $activity };    # each $activity is a hashref
  #say "<tr>$h{'id'} - $h{'name'}<br>";
  if ( not defined $h{ "moving_time" } ) {
    $h{ "x_min" } = 0;
  }
  say "<tr class=\"r" . ( ( $rownum % 2 == 1 ) ? '1' : '2' ) . "\">";    # alternating tr class
  say "  <td>
  <input type=\"checkbox\" name=\"activityID\" value=\"$h{'id'}\">
  </td>
  <td>$h{'type'}</td><td>" . TMsStrava::formatDate( $h{ 'start_date_local' }, 'datetime' ) . "</td><td>" . TMsStrava::activityUrl( $h{ "id" }, $h{ "name" } ) . "</td><td>" . TMsStrava::secToMinSec( $h{ "moving_time" } ) . "</td><td>$h{'commute'}</td><td>$h{'trainer'}</td><td>$h{'visibility'}</td>
</tr>";
} ## end foreach my $activity ( @allActivityHashes)
say '</table>
</form>';

TMsStrava::htmlPrintFooter( $cgi );
