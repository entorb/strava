#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION

# TODO
# how to set description to ""?

# IDEAS

# DONE
# after successful modification, if present all jsons are deleted
# 181026: somce changes due to stravas api changes, trainer added

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard

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
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;    # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Bulk modify activities' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

my ( @activityIDs, $commute, $trainer, $name, $description );

if ( $cgi->param('submitFromActivityList') ) {   # from list_all_activities.pl
      # say Dumper $cgi->param('activityID');
  @activityIDs = ( $cgi->param('activityID') );
  @activityIDs
      = grep {/[\d+]/g} @activityIDs;    # for security only number-only ids

} ## end if ( $cgi->param('submitFromActivityList'...))
elsif ( $cgi->param('submitFromModify') ) {    # form below
      # say Dumper $cgi->param; # debug
      # cleaning for security
  $_ = $cgi->param('activityIDs');
  s/[^0-9]+/ /g;     # for security ensure only numbers and spaces
  s/(^ +| +$)//g;    # spaces and the ends
  @activityIDs = split / /, $_;
  @activityIDs = grep { $_ > 100000 }
      @activityIDs;    # for only numbers > 100000 are making sense

  # ensure @activityIDs has unique ids
  my %h;
  foreach my $key (@activityIDs) {
    $h{$key}++;
  }
  @activityIDs = sort keys(%h);
  undef %h;

  die "ERROR: activity ID list empty" unless (@activityIDs);

  $commute = $cgi->param('commute');
  $trainer = $cgi->param('trainer');    # private was removed from stravas API
  $name    = $cgi->param('name');
  $description = $cgi->param('description');
  TMsStrava::logIt(
    "commute='$commute' trainer='$trainer' name='$name' description='$description'"
  );

  %h = ();
  if ( $commute eq "0" ) {
    $h{'commute'} = 'false';
  }
  elsif ( $commute eq "1" ) {
    $h{'commute'} = 'true';
  }
  if ( $trainer eq "0" ) {
    $h{'trainer'} = 'false';
  }
  elsif ( $trainer eq "1" ) {
    $h{'trainer'} = 'true';
  }
  $name =~ s/[^\w:_!\?\-\+\(\)\[\]\{\}]+//g
      ;    # char whitelist TODO: Umlaute missing
  if ( $name ne "" ) { $h{'name'} = '"' . $name . '"'; }
  $description =~ s/[^\w:_!\?\-\+\(\)\[\]\{\}]+//g;    # char whitelist
  if ( $description ne "" ) { $h{'description'} = '"' . $description . '"'; }

  die "ERROR: nothing to do" if ( not %h );

  # generate json string
  # goal: $json = '{ "commute": true, "private": false }';
  my $json = "{";    #
  foreach my $s (qw(commute trainer name description))
  {                  # private was removed by strava
    $json .= "\"$s\":$h{$s}, " if $h{$s};
  }
  $json = substr( $json, 0, length($json) - 2 )
      if ( length($json) > 2 );    # remove last ", "
  $json .= "}";

  # print resulting table, bad IDs result in empty row
  say '<table>
  <tr><th>
  ID</th><th>
  date</th><th>
  name</th><th>
  description</th><th>
  commute</th><th>
  training machine</th></tr>';
  foreach my $activityID (@activityIDs) {
    my ( $htmlcode, $cont )
        = TMsStrava::PostPutJsonToURL( 'PUT',
      "https://www.strava.com/api/v3/activities/$activityID",
      $s{'token'}, 1, $json );    # last parameter: 1=silent , 0=die on error
                                  # print Dumper $cont;
    my %h = TMsStrava::convertJSONcont2Hash($cont);

    # print Dumper %h;

    if ( not $h{'id'} ) {
      say
          "<tr><td colspan=6><font color=\"red\">$activityID</font></td></tr>";
    }
    else {
      say '<tr>' . '<td>'
          . $h{'id'} . '</td>' . '<td>'
          . $h{'start_date_local'} . '</td>' . '<td>'
          . $h{'name'} . '</td>' . '<td>'
          . $h{'description'} . '</td>'
          . '<td align="center">'
          . ( $h{'commute'} += 0 ) . '</td>'
          . '<td align="center">'
          . ( $h{'trainer'} += 0 ) . '</td>' . '</tr>';
    } ## end else [ if ( not $h{'id'} ) ]
  } ## end foreach my $activityID (@activityIDs)
  say '</table><hr>';

# after modification we need to cleanup the downloaded activity list jsons and stored dump files, since they are not up to date any more
  TMsStrava::clearCache();

} ## end elsif ( $cgi->param('submitFromModify'...))

# display form always
say '
<form action="activityModify.pl?session=' . $s{'session'} . '" method="post">
<table>
<tr><th>Activity IDs</th><th>Settings</th></tr>
<tr><td>
<textarea name="activityIDs" cols="10" rows="20">'
    . join( "\n", @activityIDs ) . '</textarea>
</td><td>
<table>
<tr align="center"><td>&nbsp;</td><td>1</td><td>0</td></tr>
<tr align="center"><td>commute</td>
 <td><input type="radio" name="commute" value="1"></td>
 <td><input type="radio" name="commute" value="0"></td>
</tr>
<tr align="center"><td>training machine</td>
 <td><input type="radio" name="trainer" value="1"></td>
 <td><input type="radio" name="trainer" value="0"></td>
</tr>
<tr align="center"><td>name</td>
 <td colspan="2"><input type="text" name="name" value=""></td>
</tr>
<tr align="center"><td>description</td>
 <td colspan="2"><input type="text" name="description" value=""></td>
</tr>
</table>
<input type="hidden" name="session" value="' . $s{'session'} . '">
<input type="submit" name="submitFromModify" value="Submit">
</td></tr>
</table>
</form>
';

TMsStrava::htmlPrintFooter($cgi);
