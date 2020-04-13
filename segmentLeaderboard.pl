#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Download Segment Leaderboard as Excel Sheet

# TODO

# IDEAS
# Filter by my clubs
# Fetch Segment infos

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
use lib ( '.' );
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);

# at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Segment Leaderboard', 1 );
TMsStrava::initSessionVariables( $cgi->param( "session" ) );
TMsStrava::htmlPrintNavigation();
my %formparam;
if ( $cgi->param( 'segment_id' ) and $cgi->param( 'segment_id' ) =~ m /^\d+$/ ) {
  $formparam{ 'segment_id' } = $cgi->param( 'segment_id' ) + 0;
}
if ( $cgi->param( 'date_range' ) ) { $formparam{ 'date_range' } = $cgi->param( 'date_range' ); }
if ( $cgi->param( 'club_id' ) and $cgi->param( 'club_id' ) =~ m /^\d+$/ ) { $formparam{ 'club_id' } = $cgi->param( 'club_id' ) + 0; }

say "<p>A segment ID looks like 17204908 in https://www.strava.com/segments/17204908</p>";

$formparam{ 'segment_id' } = 17204908 unless $formparam{ 'segment_id' };

my @clubs = TMsStrava::fetchClubs( $s{ 'token' } );

# display the form
say "<form action=\"segmentLeaderboard.pl\" method=\"post\">
  <input type=\"hidden\" name=\"session\" value=\"$s{ 'session' }\"/>
  <input type=\"text\" id=\"durationMin\" name=\"segment_id\" style=\"width: 100px\" value=\"" . $formparam{ 'segment_id' } . "\" >";

say "<select name=\"date_range\">";
for my $s ( qw( all_time this_year this_month this_week today) ) {
  say "<option value=\"$s\" " . ( $formparam{ 'date_range' } eq $s ? 'selected' : '' ) . ">$s</option>";
}
say "</select>";

say "<select name=\"club_id\">";
say "<option value=\"0\" " . ( $formparam{ 'club_id' } eq 0 ? 'selected' : '' ) . ">any club</option>";
for my $ref ( @clubs ) {
  my @l = @{ $ref };    # id, name, member_count, sport_type, city
  say "<option value=\"$l[0]\" " . ( $formparam{ 'club_id' } eq $l[ 0 ] ? 'selected' : '' ) . ">$l[1]</option>";
}
say "</select>";

say "<input type=\"submit\" name=\"submit\" value=\"Submit\"/> 
  </form>";

# form was submitted, so the search is performed
if ( $cgi->param( 'submit' ) ) {
  my @list = TMsStrava::fetchSegmentLeaderboard( $s{ 'token' }, $formparam{ 'segment_id' }, $formparam{ 'date_range' }, $formparam{ 'club_id' } );

  say "<table border='1'>";
  say "<tr><th>Rank</th><th>Time (s)</th><th>Name</th><th>Date</th></tr>";
  foreach my $ref ( @list ) {
    my @l = @{ $ref };

    say "<tr><td>$l[0]</td><td>$l[1]</td><td>$l[2]</td><td>$l[3]</td></tr>";
  }

  say "</table>";

} ## end if ( $cgi->param( 'submit'...))

TMsStrava::htmlPrintFooter( $cgi );
