#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Handling of Strava API auth
# Generation of access tokens, stores them in folder $s{'tmpDataFolder'}/session.txt
# deletes old tmpDataFolders

# TODO - Features
# - download detailed activities download: add a form for filtering the single activity download list
# - extract tracks as polylines and play with them, see https://developers.google.com/maps/documentation/utilities/polylineutility

# DONE
# - download activity list
# - send mail on successful auth / login
# - cleaning up the code: settings file, session id handling file
# - add several functions to one file or separate files for each action?
# - cleanup of folders -> deauth old tokens (without warning if not successful)
# - add a form for modifying activities e.g. set commute and private
# - provide .zip files containing the jsons?
# 181026: new Strava scopes implemented
# - store known locations in a separate file

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT
use autodie qw (open close)
    ;    # Replace functions with ones that succeed or die: e.g. close

# Modules: Perl Standard
use Encode qw(encode decode);
use File::Basename;    # for basename, dirname, fileparse
use File::Path qw(make_path remove_tree);

# Modules: Web
use CGI;
my $cgi = CGI->new;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

#use CGI ":all";
#use CGI qw(:standard);
use LWP::UserAgent;

use Digest::MD5 qw(md5_base64);    # for md5 coded sessions for subfolders
# use local::lib;                    # at entorb.net some modules require use local::lib!!!
use JSON;    # imports encode_json, decode_json, to_json and from_json.

# Modules: My Strava Module Lib
use lib ('.');
use lib ('/var/www/virtual/entorb/perl5/lib/perl5');
# use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;        # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Authorization' );

# Parameters for reply to Strava API
my $url = "https://www.strava.com/oauth/token";

# read from TMsStravaSecret.pm
# not working...
# use lib ( '/var/www/virtual/entorb/data-web-pages/strava/' );
use TMsStravaSecret qw( %secret );
my $clientId = $secret{'clientId'};
my $secret   = $secret{'secret'};

# cleanup for old sessions : delete old files and deauthorize old tokens
{
  my @l = <$o{'tmpDataFolderBase'}/*>;
  push @l, <$o{'tmpDownloadFolderBase'}/*>;

# TMsStrava::logIt( "cleaning up old temp data: @l" ); # logfile not here available
  foreach my $dir (@l) {
    next unless -d $dir;    # only dirs
    if ( ( stat $dir )[9] < time - $o{'ageDeleteOldDataFolders'} )
    {                       # 9 = mtime
      if ( -f "$dir/session.txt" ) {
        my $fileIn = "$dir/session.txt";
        open my $fhIn, '<', $fileIn or next;
        my @cont = <$fhIn>;
        close $fhIn;
        chomp @cont;    # remove spaces
        my ( $thatstravaUserID, $thatstravaUsername, $thattoken, $thatscope )
            = @cont;
        TMsStrava::deauthorize( $thattoken, 1 )
            ;           # 2nd paramter-> 1=silent , 0= die on error
      } ## end if ( -f "$dir/session.txt")
      remove_tree($dir);
    } ## end if ( ( stat $dir )[9] ...)
  } ## end foreach my $dir (@l)
}    # delete old files

# Idea: Display greeting if session is already present? TODO: check if session is valid
# -> Nope not making sense!
# if ($cgi->param("session")) {
# my ($s{'stravaUserID'},$s{'stravaUsername'},$token,$s{'scope'}) = TMsStrava::initSessionVariables ($s{'session'});
# }

if ( not $cgi->param("code") ) {    # and not $cgi->param("session") ?
      # if not, this a new visiter (or one owning a token / session already?)
      # die("ERROR: parameter 'code' missing");

# All user data and login tokens are periodically deleted for reasons of privacy and security. Therefore (re-) authorization of this app is required at each session.
  say '
<a href="/strava/">start over</a>
&nbsp;
<a href="/contact.php?origin=strava">Contact me</a>
&nbsp;
<a href="/impressum.php">Website Disclaimer</a>
';

} ## end if ( not $cgi->param("code"...))
else {    # param("code") is set -> visitor coming from strava auth page

  # debug: print all parameters
  # say $cgi->param;
  # say "url_param"; print Dumper $cgi->url_param; # not needed

  # reading parameters for generation of access_token
  my $exchangecode = $cgi->param("code");
  $s{'scope'} = $cgi->param("scope");
  if ( $s{'scope'} eq "" ) { $s{'scope'} = "public"; }

  # say "<p>code=$exchangecode<br>scope=$s{'scope'}</p>";

# 1. HTTP Post form data to Strava API (and fetch JSON response)
#
# example: curl -X POST $url \ -F client_id=$clientId \ -F client_secret=$secret \ -F code=$exchangecode
#
  my $ua = LWP::UserAgent->new();    # create User Agent using LWP
  my %h;
  $h{'client_id'}       = $clientId;
  $h{'client_secret'}   = $secret;
  $h{'code'}            = $exchangecode;
  $h{'Accept'}          = 'application/json';
  $h{'Accept-Encoding'} = 'UTF-8';

  my $res = $ua->post( $url, \%h );    # this is strava servers response

  if ( not $res->is_success ) {
    say "<h2>ERROR at authentication</h2>";
    say "HTTP get code: ", $res->code,    "<br>";
    say "HTTP get msg : ", $res->message, "<br>";
    die;
  } ## end if ( not $res->is_success)
  %h = undef;

  # my $json = decode( 'UTF-8',  $res->as_string() );
  my $json = decode( 'UTF-8', $res->decoded_content );

  # print "<br>Cont=$json";

# 2. extract access_token and username/id from the json attachment
# $json =~ m/"access_token":"([^"]+)","athlete":{"id":(\d+),"username":"([^"]+)"/;
# ($s{'token'}, $s{'stravaUserID'}, $s{'stravaUsername'}) = ($1,$2,$3);
  my %h2      = TMsStrava::convertJSONcont2Hash($json);
  my %athlete = %{ $h2{'athlete'} };
  ( $s{'token'}, $s{'stravaUserID'}, $s{'stravaUsername'} )
      = ( $h2{'access_token'}, $athlete{'id'}, $athlete{'username'} );

# say "<p>id=$s{'stravaUserID'}, user=$s{'stravaUsername'}, scope=$s{'scope'}, access_token=$s{'token'}</p>";
  if ( not $s{'token'} =~ m/[0-9a-f]{40}/ ) {  # sollte 40 hex chars lang sein
    die "ERROR: no or bad access_token";
  }

# 3. generate session from userID and time and store it on the server, Idea: alternative: store in browser cookie NO: since I do not want make it work without cookie support.
  $_ = "$s{'stravaUserID'}" . '_' . time;
  $s{'session'} = md5_base64($_);
  $s{'session'} =~ s/\//-/sg;                  # kein / in ID wegen path
  $s{'session'} =~ s/\+/_/sg;                  # kein + in ID wegen url

  $s{'tmpDataFolder'} = "$o{'tmpDataFolderBase'}/$s{'session'}";

  my $fileOut = "$s{'tmpDataFolder'}/session.txt";
  $_ = dirname($fileOut);
  make_path $_ unless -d $_;

# TMsStrava::logIt("writing to session file $fileOut"); not available before initSessionVariables
  open my $fhOut, ">", $fileOut
      or die "ERROR: Can't write to file '$fileOut': $!";
  print {$fhOut}
      "$s{'stravaUserID'}\n$s{'stravaUsername'}\n$s{'token'}\n$s{'scope'}";
  close $fhOut;

  # Check for present and valid parameter session
  # TMsStrava::initSessionVariables ($cgi->param("session"));
  TMsStrava::initSessionVariables( $s{'session'} );
  TMsStrava::logIt("Auth complete");
  TMsStrava::logIt("response content was (UTF-8-decoded):\n$json");

  @_ = TMsStrava::whoAmI( $s{'token'} );

  # 	TMsStrava::logIt("WhoAmI:@_");

  # manually printing of navi bar, copied from htmlPrintHeader
  TMsStrava::htmlPrintNavigation();
  say "<h2>Welcome</h2>";

  TMsStrava::logIt(
    "<p>Token for user '$s{'stravaUsername'}' with scope '$s{'scope'}' successfully exchanged</p>"
  );
  say
      "<p>Please start by clicking on cache activities button to the left. Be patient, it takes a little while (&asymp;30s per 1000 activities). If you have many activities on Strava, you better use the per year button.</p>";

  # copied from index.html
  say '
<h3>List of Changes</h3>
	<ul>
		<li>2023-06-12: fancy activity statistics charts</li>
		<li>2023-06-08: usage stats: 2697 unique and 669 returning users. </li>
		<li>2020-07-24: usage stats: this tool passed the 1000-unique-users milestone!</li>
		<li>2020-07-21: fancy activity table</li>
		<li>2020-01-06: published source code on <a href="https://github.com/entorb/strava/" target="_blank">GitHub</a></li>
		<li>2019-06-08: top10 activities</li>
		<li>2019-05-21: starred segments overview</li>
		<li>2019-05-21: Excel import of activities</li>
		<li>2019-05-16: limited caching to max 1000 activities per run and optimized performance, to prevent timeouts</li>
		<li>2019-05-05: charts for activity statistics</li>
		<li>2019-04-03: nearest city via an offline database of cities\'s geo location, created from <a href="https://www.maxmind.com" target="_blank">MaxMind\'s GeoLite2 data</a></li>
		<li>2019-03-20: search for activities</li>
		<li>2019-01-12: activities sorted now ASC by date, statistics extended to record speed and elevation/distance</li>
		<li>2019-01-03: gear name (bike/shoe) in Excel export</li>
		<li>2018-12-05: activity statistics</li>
		<li>2018-11-30: caching of activities per year, besides caching of all at once, to prevent timeout issues</li>
	</ul>';

# <h3>Feature ideas</h3>
# <ul>
# <li>find some use for the polymap</li>
# <li>stats for starred segments (access to segment leaderboard not possible due to changes in api, premium account required?)</li>
# </ul>

  say
      "<p><small>strava user=$s{'stravaUsername'} user id=$s{'stravaUserID'} scope=$s{'scope'} session=$s{'session'}</small></p>";

  # log login and send E-Mail for torben only if write-session-log = 1
  if ( $s{'stravaUserID'} != 7656541 )
  { # or ( $s{ 'stravaUserID' } == 7656541 and $s{ 'write-session-log' } == 1 ) ) {
    @_ = localtime time;
    my $datestr = sprintf '%02d.%02d.%04d %02d:%02d:%02d', $_[3], $_[4] + 1,
        $_[5] + 1900, $_[2], $_[1], $_[0];
    my $subject = "auth. by '$s{'stravaUsername'}', scope '$s{'scope'}'";
    my $body
        = "$datestr\t$s{'stravaUserID'}\t$s{'stravaUsername'}\t$s{'scope'}\n";
    $body
        .= "$athlete{'firstname'} $athlete{'lastname'} from $athlete{'country'}\n";
    $body .= "https://www.strava.com/athletes/$s{'stravaUserID'}\n";
    # TODO: use SQLite instead
    $fileOut = $o{'dataFolderBase'} . '/login.log';
    if ( open $fhOut, '>>', $fileOut ) {    # don't care if not ;-)
      print {$fhOut}
          "$datestr\t$s{'stravaUserID'}\t$s{'stravaUsername'}\t$s{'scope'}\n";
      close $fhOut;
    }
# TODO: do not send these emails any more
# TMsStrava::send_mail( $subject, $body, $secret{ 'my-email' } );    # not for torben
  } ## end if ( $s{'stravaUserID'...})
}    # end of token exchange

TMsStrava::htmlPrintFooter($cgi);

