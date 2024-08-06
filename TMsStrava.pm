package TMsStrava;
# by Torben Menke https://entorb.net

# DESCRIPTION
# Package for Strava app

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT
use autodie qw (open close)
    ;    # Replace functions with ones that succeed or die: e.g. close

# use local::lib;               # at entorb.net some modules require use local::lib!!!
use lib ('/var/www/virtual/entorb/perl5/lib/perl5');

# Modules: Perl Standard
use Encode qw(encode decode);
use File::Basename;    # for basename, dirname, fileparse
use File::Path qw(make_path remove_tree);

use Exporter qw(import)
    ; # gives you Exporter's import() method directly -> use for exporting variables via our @EXPORT
our @EXPORT
    = qw( %o %s);    # o = Global Settings / Options ; s = Session variables
# use parent 'Exporter'; # imports and subclasses Exporter
# our @EXPORT = qw($var); # put stuff here you want to export
# put vars into @EXPORT_OK that will be exported on request

use Time::HiRes('time');    # -> time() -> float of seconds
use Time::Local;            # date vars -> timestamp

use Storable;               # read and write variables to

# Modules: CPAN
use LWP::UserAgent; # http requests
use JSON;           # imports encode_json, decode_json, to_json and from_json.
# important: install JSON::XS as well, as JSON uses it, if present, and it is MUCH faster

our %o;             # Global Settings / Options, is exported, see above
our %s;             # Session variables, is exported, see above
$o{'dataFolderBase'}        = '/var/www/virtual/entorb/data-web-pages/strava';
$o{'tmpDataFolderBase'}     = $o{'dataFolderBase'} . '/tmp';
$o{'tmpDownloadFolderBase'} = './download';
$o{'dirKnownLocationsBase'} = $o{'dataFolderBase'} . '/knownLocations';
$o{'ageDeleteOldDataFolders'} = 7200;                                     # s
$o{'urlStravaAPI'}            = "https://www.strava.com/api/v3";
$o{'cityGeoDatabase'}         = $o{'dataFolderBase'} . '/city-gps.dat';

$s{'tsStart'} = time;    # timestamp of start
# TODO: logging enable/disable
$s{'write-session-log'} = 1;    # Write session logfile

# tmpDataFolder and tmpDownloadFolder are set after session is known
# $s{'tmpDataFolder'}; # is set later the session is appended
# $s{'tmpDownloadFolder'}; # later the session is appended

use constant PI => 4 * atan2( 1, 1 );


sub whoAmI {
  # fetch athlete info from strava
  # in: Token
  # out: UserID, Username
  my ($token) = @_;
  logSubStart('whoAmI');
  my $cont = getContfromURL( "$o{'urlStravaAPI'}/athlete", $token );
  my %h    = convertJSONcont2Hash($cont);
  return ( $h{'id'} + 0, $h{'username'} );
} ## end sub whoAmI


sub logIt {
  # append to sessionlogfile, with is overwritten for each website action
  # in: $str to append to logfile, only if $s{'FhSessionLog'} == is set
  # out: nothing
  my ($string) = @_;
  # logSubStart ('logIt');
  if ( my $fh = $s{'FhSessionLog'} ) {    # only if session logging is enabled
    $_ = sprintf '%.1fs', ( time - $s{'tsStart'} );
    say {$fh} $_ . "\t" . $string;
  }
  return;
} ## end sub logIt


sub logSubStart {
# logs the start of a sub / method
# in: $str to pass to log ( in log the check if $s{'write-session-log'} == 1 is performed)
  my ($str) = @_;
  # logSubStart ('logIt');
  logIt("=== start of sub: $str ===");
  return;
} ## end sub logSubStart


sub initSessionVariables {
 # validates $session
 # read stored session.txt from "$o{'tmpDataFolderBase'}/$session/session.txt"
 # sets $s{'tmpDataFolder'} and   $s{'tmpDownloadFolder'}
 # in: $session
 # out : nothing
 # former out: Array of ($stravaUserID,$stravaUsername,$token,$scope)
  my ($session) = @_;
# $session = 'cGjopr0eSVOVXC9_JJOW2A' ; ##TODO: set session for run via terminal
  logSubStart('initSessionVariables');
  logIt("session = '$session'");
  if ( $session eq '' ) {
    die "ERROR: bad session '$session'";
  }
  if ( not $session =~ m/^[a-zA-Z0-9_\-]+$/ ) {
    die "ERROR: bad session '$session'";
  }
  $s{'session'}           = $session;
  $s{'tmpDataFolder'}     = "$o{'tmpDataFolderBase'}/$session";
  $s{'tmpDownloadFolder'} = "$o{'tmpDownloadFolderBase'}/$session";
  $s{'pathToActivityListHashDump'}
      = "$s{'tmpDataFolder'}/activityList/activityList-Array.dmp";
  $s{'pathToActivityListJsonDump'}
      = "$o{'tmpDownloadFolderBase'}/$session/activityList.json";
  $s{'pathToGearHashDump'}  = "$s{'tmpDataFolder'}/gear.dmp";
  $s{'pathToClubsHashDump'} = "$s{'tmpDataFolder'}/clubs.dmp";

  # update timestamp of temp dir to extent session expire date
  system( "touch", $s{'tmpDataFolder'} );

  my $fileIn = "$s{'tmpDataFolder'}/session.txt";
  if ( not -f $fileIn ) {
    say
        "Uops, it seems your session '$session' has expired. Please start a <a href=\"./index.html\">new session</a>.";
    exit;
  }
  # say $fileIn and die;
  open my $fhIn, '<', $fileIn or die "ERROR: bad session '$session'";
  my @cont = <$fhIn>;
  close $fhIn;
  chomp @cont;    # remove spaces

  if ( $s{'write-session-log'} == 1 ) {
    my $fileLog = "$s{'tmpDataFolder'}/log-session.log";
    open my $fhIn, '>>', $fileLog
        or die "ERROR: can't write to session logfile'";
    print {$fhIn} "\n\n\n\n";
    $s{'FhSessionLog'} = $fhIn;
    # not closed: not nice, but makes life easier...
  } ## end if ( $s{'write-session-log'...})

# check stored user ID vs. user ID via Strava API
# not needed
# my ($stravaUserID2, $stravaUsername2) = TMsStrava::whoAmI($token);
# if ($stravaUserID2 ne $stravaUserID or $stravaUsername2 ne $stravaUsername) {
# die("ERROR: bad session");
# }

  ( $s{'stravaUserID'}, $s{'stravaUsername'}, $s{'token'}, $s{'scope'} )
      = @cont;
  $s{'fileKnownLocations'}
      = "$o{'dirKnownLocationsBase'}/$s{'stravaUserID'}.txt";
# return @cont; # ($stravaUserID,$stravaUsername,$token,$scope)	# not used any more, now this is stored in %s
  return;
} ## end sub initSessionVariables


sub clearDownload {
  logSubStart('clearDownload');
  unlink foreach (<$s{'tmpDownloadFolder'}/*.ics>);
  unlink foreach (<$s{'tmpDownloadFolder'}/*.json>);
  unlink foreach (<$s{'tmpDownloadFolder'}/*.xlsx>);
  unlink foreach (<$s{'tmpDownloadFolder'}/*.zip>);
  return;
} ## end sub clearDownload


sub clearCache {
  logSubStart('clearCache');
# after modification I cleanup this session's downloaded activity list jsons and stored dump files, since they are not up to date any more
  unlink foreach (<$s{'tmpDataFolder'}/activityList/*.json>);    #
  unlink foreach (<$s{'tmpDataFolder'}/activityList/*.dmp>);
  clearDownload();
# unlink foreach (<$s{'tmpDataFolder'}/activitySingle/*.json>); # TODO after implementing single activity json download
  return;
} ## end sub clearCache


sub deauthorize {
  my ( $token, $silent ) = @_;
  # in: token, silent [0,1] (1-> do not die on error)
  # out: nothing
  logSubStart('deauthorize');
  my ( $htmlcode, $cont )
      = PostPutJsonToURL( 'POST', "https://www.strava.com/oauth/deauthorize",
    $token, $silent );
  # my %h = convertJSONcont2Hash($cont);
  return;
} ## end sub deauthorize


sub fetchActivitySingle {
# fetch detailed activity, store JSON in file system
# IDEA: change filename to ID only? For better web access? Advantage of date first is sort order...
# output location: "$s{'tmpDataFolder'}/activitySingle/" . $date . "-" . $h{"type"} . "-$id" . ".json";
# in: $token, $id of activity, $txt [0,1] -> 1 generates .txt files from the jsons
  my ( $token, $id, $txt ) = @_;
  logSubStart('fetchActivitySingle');
  my $cont = getContfromURL(
    "$o{'urlStravaAPI'}/activities/$id?include_all_efforts=true", $token );

  my %h = convertJSONcont2Hash($cont);

  my $date = $h{"start_date_local"};    # 2018-08-21T08:14:53Z
  $date =~ m/^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/
      or die "E: activity date '$date' not matching '2018-08-21T08:14:53Z'";
  $date = "$1$2$3-$4$5";

  # my $fileOut = "activities/activity.json";
  my $fileOut
      = "$s{'tmpDataFolder'}/activitySingle/"
      . $date . "-"
      . $h{"type"} . "-$id" . ".json";
  $_ = dirname($fileOut);
  make_path $_ unless -d $_;

  open my $fhOut, '>:encoding(UTF-8)', $fileOut
      or die("ERROR: Can't write to file '$fileOut': $!");
  print {$fhOut} $cont;
  close $fhOut;

  # .txt output
  if ( $txt == 1 ) {
    $fileOut =~ s/\.json$/.txt/;
    open $fhOut, '>:encoding(UTF-8)', $fileOut
        or die("ERROR: Can't write to file '$fileOut': $!");
    foreach my $k ( sort keys %h ) {
      next if ( not defined $h{$k} );
      my $s = $h{$k};
      $s = ref2String($s);
      print {$fhOut} "$k\t: $s\n";
    } ## end foreach my $k ( sort keys %h)
    close $fhOut;
  } ## end if ( $txt == 1 )
  return;
} ## end sub fetchActivitySingle


sub getContfromURL {
  # retrieve content from url, using HTTP GET
  # in: $url, $token
  # returns string of contents
  my ( $url, $token ) = @_;    # () important!!!
  logSubStart('getContfromURL');
  logIt("url='$url', token='$token'");
  my $req = HTTP::Request->new( GET => $url );
  $req->header( 'Accept'          => 'application/json' );
  $req->header( 'Accept-Encoding' => 'UTF-8' );
  $req->header( 'Authorization'   => "Bearer $token" );

  # creat User Agent using LWP
  my $ua = LWP::UserAgent->new();
  # TODO: App Name
  # $ua->agent("MyApp/0.1 ");

  my $res = $ua->request($req);
  if ( not $res->is_success ) {
    print "HTTP get code: ", $res->code,    "\n";
    print "HTTP get msg : ", $res->message, "\n";
    use Data::Dump qw/ dd /;
    dd( $res->as_string );
    $_ = $res->code . ": " . $res->message;
    die "ERROR: $_";
  } ## end if ( not $res->is_success)
  my $cont = $res->decoded_content;    # content, decoded if it was zipped
  $cont = decode( 'UTF-8', $cont )
      ; # for some reason this is required and not included in $res->decoded_content
        # logIt("response content:\n$cont");
  return $cont;
} ## end sub getContfromURL


sub PostPutJsonToURL {
  # Put/Update/Set content to url, using HTTP PUT
  # in:
  # $postPut [POST, PUT]
  # $url
  # $token
  # $silent [0,1] (1-> do not die on http error)
  # $json content, can be ""
  # out: string of contents
  my ( $postPut, $url, $token, $silent, $json ) = @_;    # () important!!!
  logSubStart('PostPutJsonToURL');
  logIt("$postPut url='$url', token='$token'");
  my $req;
  if ( $postPut eq 'POST' ) {
    $req = HTTP::Request->new( POST => $url );
  }
  elsif ( $postPut eq 'PUT' ) {
    $req = HTTP::Request->new( PUT => $url );
  }
  else {
    die "Bad parameter '$postPut'";
  }
  logIt("json-content:\n$json");
  $req->content($json);
  $req->header( 'Accept'          => 'application/json' );
  $req->header( 'Accept-Encoding' => 'UTF-8' );
  $req->header( 'Authorization'   => "Bearer $token" );
  $req->header( 'Content-Type'    => 'application/json' );
  #creat User Agent using LWP
  my $ua = LWP::UserAgent->new();
  # $ua->agent("MyApp/0.1 ");
  # $ua->default_header( 'Content-Type'    => "application/json" );

  my $res      = $ua->request($req);
  my $htmlcode = $res->code;
  if ( $silent == 0 and not $res->is_success ) {
    print "HTTP get code: ", $htmlcode,     "\n";
    print "HTTP get msg : ", $res->message, "\n";
    #        use Data::Dump qw/ dd /;
    #        dd( $res->as_string );
    die "leaving";
  } ## end if ( $silent == 0 and ...)
  my $cont = $res->decoded_content;    # content, decoded if it was zipped
  $cont = decode( 'UTF-8', $cont );
  logIt("response content:\n$cont");
  return ( $htmlcode, $cont );
} ## end sub PostPutJsonToURL


sub convertJSONcont2Hash {
  # in: json string, containing a single json object
  # out: a single hash (multidimensional)
  my ($cont) = @_;    # () important!!!
  logSubStart('convertJSONcont2Hash');
  # say "<p><code>debug for Dave 2:<br>json= '$cont'</code></p>";
  my $j       = JSON->new->allow_nonref;
  my $decoded = {};                        # empty hash ref
  if ( length($cont) > 0 ) {
    $decoded = $j->decode($cont);
    die "E: message '$decoded' is no HASHREF"
        if ( not ref($decoded) eq "HASH" );
  }
  return %{$decoded};                      # ref -> hash
} ## end sub convertJSONcont2Hash


sub convertJSONcont2Array {
  # in: json string, containing a list of json objects
  # out: an array containing hashes
  my ($cont) = @_;    # () important!!!
  logSubStart('convertJSONcont2Array');
  my $decoded = JSON->new->allow_nonref->decode($cont);
  # my $j       = JSON->new->allow_nonref;
  # my $decoded = $j->decode($cont);
  die "E: message '$decoded' is no ARRAYREF"
      if ( not ref($decoded) eq "ARRAY" );
  return @{$decoded};    # ref -> list
} ## end sub convertJSONcont2Array

# sub convertArray2Hash {
# # in: array
# # out: hash, indexed by array index
# # convert array to hash, indexed by number $i
# # not used any more, but might be of use later?
#     my @L = @_;
#     my %h;
#     for my $i ( 0 .. $#L ) {
#         $h{$i} = $L[$i];
#     }
#     return %h;
# }


sub ref2String {
# used for converting hash values, being a hashref oder an arrayref itself to a string
# in: $field = a value of a hash entry
# out: string $field, if $field is a hash or array ref, it is converted to a string, recursively
#  else $field is returned untouched
  my ($field) = @_;
  # logSubStart ('ref2String');
  if ( ref($field) eq 'HASH' ) {
    my %h = %{$field};
    my $s = "";
    foreach my $k ( sort keys %h ) {
      if ( not defined $h{$k} ) { $h{$k} = ""; }
      my $s2 = $h{$k};
      if ( ref($s2) eq 'HASH' or ref($s2) eq 'ARRAY' ) {
        $s2 = ref2String($s2);    # recursion
      }
      $s .= "$k=$s2, ";
    } ## end foreach my $k ( sort keys %h)
    $s = substr $s, 0, length( $s - 2 );    # remove last ', '
    $field = "{$s}";
  } ## end if ( ref($field) eq 'HASH')
  elsif ( ref($field) eq 'ARRAY' ) {
    my @L = @{$field};
    my $s = "";
    foreach my $s2 (@L) {
      if ( ref($s2) eq 'HASH' or ref($s2) eq 'ARRAY' ) {
        $s2 = ref2String($s2);    # recursion
      }
      $s .= "$s2, ";
    } ## end foreach my $s2 (@L)
    $s = substr $s, 0, length($s) - 2;    # remove last ', '
    $field = "[$s]";
  } ## end elsif ( ref($field) eq 'ARRAY')
  return $field;
} ## end sub ref2String


sub convertJsonFilesToArrayOfHashes {
  # in: @L list of json filenames
  # out: array of hashes of the json contents
  #  array of hashes, to ensure the order of the elements
  # writes the array to a .dmp file for reuse
  my @L = @_;    # List of JSON files
  logSubStart('convertJsonFilesToArrayOfHashes');
  my @allActivityHashes;
  foreach my $fileIn (@L) {
    open my $fhIn, '<:encoding(UTF-8)', $fileIn
        or die "ERROR: Can't read from file '$fileIn': $!";
    my $cont;
    {
      $/    = undef;     # slurp
      $cont = <$fhIn>;
    }
    close $fhIn;

    if ( $cont =~ m/^\[\{/ )
    {    # for activityList the decoded JSON is a List -> ARRAYREF
      my @activitiesOfThisFile = convertJSONcont2Array($cont);
      push @allActivityHashes, @activitiesOfThisFile;
    }
    elsif ( $cont =~ m/^\{/ )
    {    # for single activity the decoded JSON is a Hash -> HASHREF
      my %h = convertJSONcont2Hash($cont);
      push @allActivityHashes, $_;
    }
    print ".<br>";
  }    # foreach my $fileIn (@L)
  return @allActivityHashes;
} ## end sub convertJsonFilesToArrayOfHashes


sub extractActivityIdFromJsonFiles {
  # read stored JSONs (of the activities) and extract activity IDs
  # in: @L # Array of JSON files
  # out: @IDs # Array of IDs
  # TODO: use ..dmp file instead? or pace this logic into another sub
  my @L = @_;    # List of JSON files
  logSubStart('extractActivityIdFromJsonFiles');
  my @IDs;
  my @allActivityHashes = convertJsonFilesToArrayOfHashes(@L);
  foreach my $activity (@allActivityHashes) {
    my %h = %{$activity};    # each $activity is a hashref
        # say "$h{'id'}\t$h{'type'}\t$h{'start_date_local'}\t$h{'name'}";
    push @IDs, $h{'id'};
  }
  return @IDs;
} ## end sub extractActivityIdFromJsonFiles


sub getKnownLocationsOfUser {
  # $stravaUserID fetched from $s
  # out: @knownLocations as array of arrays: [$lat,$lon,$description]
  logSubStart('getKnownLocationsOfUser');
  # my $stravaUserID = $s{'stravaUserID'};
  my @knownLocations = ();
  # some global hard coded ones
  @knownLocations = (
    [ 49.574986, 10.967483, "ER-Schaeffler-SMB" ],
    [ 51.070298, 13.760067, "DD-Alaunpark" ],
    [ 53.330333, 10.138152, "P-MTV-Pattensen" ],
    [ 51.010218, 13.701419, 'DD-Robotron' ],
    [ 49.60579,  11.036603, 'ER-Meilwald-Handtuchwiese' ],
    [ 49.588036, 11.035357, "ER-ObiKreisel" ]
  );

  # logIt("knownLocations bevor");
  # logIt(Dumper \@knownLocations);
  push @knownLocations, readKnownLocationsFromFile();
  # logIt("knownLocations danach");
  # logIt(Dumper \@knownLocations);
  return @knownLocations;
} ## end sub getKnownLocationsOfUser


sub readKnownLocationsFromFile {
# Read known locations from file $stravaUserID.txt
# format of file: "$lat $lon "description (without spaces)\n" , so separated columns by " "
# In: nothing
# out @knownLocations as array of arrays: [$lat,$lon,$description]
  my $filename = "$o{'dirKnownLocationsBase'}/$s{'stravaUserID'}.txt";
  logSubStart('readKnownLocationsFromFile');
  my @knownLocations = ();
  if ( -f $filename ) {
    # say "$filename found";
    open my $fhIn, '<:encoding(UTF-8)', $filename or die;
    my @L2;
    {
      $/  = "\n";      # set end of line for reading of file
      @L2 = <$fhIn>;
      close $fhIn;
    }
    chomp @L2;         # remove \n from lineend
    my $i = 0;
    foreach my $line (@L2) {
      # logIt ("$i: $line");
      my @L3 = split " ", $line;
      $knownLocations[$i] = [ $L3[0] + 0, $L3[1] + 0, $L3[2] ];
      $i++;
    } ## end foreach my $line (@L2)
  } ## end if ( -f $filename )
  # logIt ("Number of items in knownLocations:" . $#knownLocations) ;
  # logIt ("readKnownLocationsFromFile : knownLocations = ");
  # logIt (Dumper \@knownLocations);
  return @knownLocations;
} ## end sub readKnownLocationsFromFile


sub convertActivityHashToExcel {
  # converts hash of activities and exports to an excel file
  # creates path to output file if not present
  # in: $fileNameExcel
  #     @L allActivityHashes of activities
  # out: excel file: $fileOutExcel = "$s{'tmpDownloadFolder'}/$fileNameExcel";
  # Info:
  # average_watts = kilojoules * 1000 * moving_time
  # average_cadence = halbe Schrittfreq
  # new calculated fields are marked with x_

  my $fileNameExcel     = shift;
  my @allActivityHashes = @_;      # List of JSON files
  logSubStart('convertActivityHashToExcel');

  my $fileOutExcel = "$s{'tmpDownloadFolder'}/$fileNameExcel";
  $_ = dirname($fileOutExcel);
  make_path $_ unless -d $_;

# check for each activity which parameters are present, to ensure that all parameters are included
  my %hashOfActivitiyParameters;
  foreach my $activity (@allActivityHashes) {
    my %h = %{$activity};    # each $activity is a hashref
    foreach my $key ( keys %h ) {
      $hashOfActivitiyParameters{$key}++;
    }
  } ## end foreach my $activity (@allActivityHashes)

  # # count how often each activity parameter is used
  # my %h = %hashOfActivitiyParameters;
  # foreach my $k ( sort keys(%h) ) {
  #     say "$k\t$h{$k}";
  # }

  # export all activities and all parameters to a new Excel sheet
  use Excel::Writer::XLSX;
  logIt("creating Excel '$fileOutExcel'");
  my $workbook = Excel::Writer::XLSX->new($fileOutExcel)
      or die "ERROR: Can't open $fileOutExcel for writing!\n";
  $workbook->set_properties(
    title    => 'Strava Excel Activity Export',
    author   => 'Torben Menke',
    comments =>
        'https://entorb.net/strava/ created with Perl and Excel::Writer::XLSX',
    category => 'Sport'
  );
  my $worksheet       = $workbook->add_worksheet("ActivityListData");
  my $formatHeaderRow = $workbook->add_format( bold => 1 );   # color => 'red'

  my $formatDate
      = $workbook->add_format( num_format => 'dd.mm.yyyy hh:mm:ss' )    #
      ;    # for *display* in Excel

 # Add a handler to store the width of the longest string written to a column.
 # We use the stored width to simulate an autofit of the column widths.
 #
 # You should do this for every worksheet you want to autofit.
  $worksheet->add_write_handler( qr[\w], \&excel_store_excel_string_widths );

  my @Reihenfolge;
  @Reihenfolge = qw(
      id
      type
      x_gear_name
      start_date_local
      x_week
      x_start_h
      name
      x_min
      x_km
      x_min/km
      km/h
      x_max_km/h
      x_mi
      x_min/mi
      x_mph
      x_max_mph
      total_elevation_gain
      x_elev_m/km
      average_heartrate
      max_heartrate
      average_cadence
      average_watts
      kilojoules
      commute
      private
      visibility
      workout_type
      x_nearest_city_start
      x_start_locality
      x_end_locality
      x_dist_start_end_km
      start_latlng
      end_latlng
      elev_low
      elev_high
      kudos_count
      comment_count
  );

  # now add the remaining fields
  # get the delta
  my %in_R = map { $_ => 1 } @Reihenfolge;
  push @Reihenfolge,
      grep { not $in_R{$_} } sort keys %hashOfActivitiyParameters;

  # print Dumper @Reihenfolge;
  my $s    = \@Reihenfolge;
  my $line = 0;                                           # starts at 0
  $worksheet->write( $line, 0, $s, $formatHeaderRow );    # header row

  # klappt leider nicht:
  # # write format into column C (date)
  # for my $i ( 2 .. 10 ) {
  #     $worksheet->write( $i, 2, "", $formatDate );
  # }

  foreach my $activity (@allActivityHashes) {
    my %h = %{$activity};    # each $activity is a hashref
                             # say $h{"name"};

    # $h{"date"} = convertDate4Excel( $h{"start_date_local"} );

    my @L = map { $h{$_} } @Reihenfolge;

    # for (my $i=0; $i<=$#Reihenfolge; $i++) {
    #     say "$Reihenfolge[$i] : $L[$i]";
    # }
    # die;

    foreach my $field (@L) {
      # some fields are hashrefs or arrayrefs
      # convert them to a string
      if ( not defined $field ) {
        $field = "";
      }
      elsif ( ref($field) eq 'HASH' or ref($field) eq 'ARRAY' ) {
        $field = ref2String($field);
        if ( length($field) > 64 ) {
          $field = substr( $field, 0, 64 ) . '...';
        }
      } ## end elsif ( ref($field) eq 'HASH'...)
    }    # foreach my $field (@L)

    $s = \@L;
    $line++;
    $worksheet->write( $line, 0, $s );    # data row
        # TODO: overwrite data formatted using date format

# Excel requires dates to be formatted in ISO8601 format
# 2018-08-28 or 2018-08-28T14:24:22+00:00 or 2018-08-28T14:24:22Z or 20180828T142422Z
    my $index;
    ($index)
        = grep { $Reihenfolge[$_] eq "start_date_local" } 0 .. $#Reihenfolge;
    $worksheet->write_date_time( $line, $index, $h{"start_date_local"},
      $formatDate );
    ($index) = grep { $Reihenfolge[$_] eq "start_date" } 0 .. $#Reihenfolge;
    $worksheet->write_date_time( $line, $index, $h{"start_date"},
      $formatDate );

  } ## end foreach my $activity (@allActivityHashes)

  # Run the autofit after you have finished writing strings to the workbook.
  excel_autofit_columns($worksheet)
      ; # from # https://metacpan.org/pod/Spreadsheet::WriteExcel::Examples#Example:-autofit.pl
  $workbook->close;
  return;
} ## end sub convertActivityHashToExcel


sub convertFetchedActivityListJsonFilesToExcel {
# wrapper for backward compatibility
# converts array of filenames to list of hashes
# calls convertActivityHashToExcel
# in: $fileNameExcel
#     $refKnownLocations arrayref of known locations
#     @L Array of filenames of json files of activities, either one file per activity or files containing lists of activities
# out: excel file: $fileOutExcel = "$s{'tmpDownloadFolder'}/$fileNameExcel";
  my $fileNameExcel     = shift;
  my $refKnownLocations = shift;
  my @L                 = @_;      # List of JSON files
  logSubStart('convertFetchedActivityListJsonFilesToExcel');
  my @allActivityHashes = convertJsonFilesToArrayOfHashes(@L);
  convertActivityHashToExcel( $fileNameExcel, $refKnownLocations,
    @allActivityHashes );
  return;
} ## end sub convertFetchedActivityListJsonFilesToExcel


sub sortArrayHashRefsNumAsc {
  my ( $fieldname, @list ) = @_;
  my @sorted = sort {
    my ( $aRef, $bRef ) = ( $a, $b );
    my %aHash = %{$aRef};
    my %bHash = %{$bRef};
    $aHash{$fieldname} <=> $bHash{$fieldname};
  } @list;
  return @sorted;
} ## end sub sortArrayHashRefsNumAsc


sub sortArrayHashRefsNumDesc {
  my ( $fieldname, @list ) = @_;
  my @sorted = sort {
    my ( $aRef, $bRef ) = ( $a, $b );
    my %aHash = %{$aRef};
    my %bHash = %{$bRef};
    $bHash{$fieldname} <=> $aHash{$fieldname};
  } @list;
  return @sorted;
} ## end sub sortArrayHashRefsNumDesc


sub sortArrayHashRefsAbcAsc {
  my ( $fieldname, @list ) = @_;
  my @sorted = sort {
    my ( $aRef, $bRef ) = ( $a, $b );
    my %aHash = %{$aRef};
    my %bHash = %{$bRef};
    $aHash{$fieldname} cmp $bHash{$fieldname};
  } @list;
  return @sorted;
} ## end sub sortArrayHashRefsAbcAsc


sub zipFiles {
  # Zipping of activityJSONs
  # in: $pathToZip, @files , both in absolute path
  # out: nothing
  my ( $pathToZip, @files ) = @_;
  logSubStart('zipFiles');
  logSubStart( join "\n", @files );
  use IO::Compress::Zip qw(zip $ZipError);
  zip \@files    => $pathToZip,
      FilterName => sub {s<.*[/\\]><>}    # trim path, filename only
      ,
      TextFlag =>
      1 # It is used to signal that the data stored in the zip file/buffer is probably text.
      ,
      CanonicalName =>
      1 # This option controls whether the filename field in the zip header is normalized into Unix format before being written to the zip file.
      ,
      ZipComment => "Created by Torben's Strava App https://entorb.net/strava"
      # , Level => 9 # [0..9], 0=none, 9=best compression
      or die "zip failed: $ZipError\n";
  return;
} ## end sub zipFiles


sub fetchSegmentsStarred {
  # fetch starred segments from Strava
  # in: Token
  # out: array of SummarySegment
  my ($token) = @_;
  logSubStart('fetchSegmentsStarred');
  my $cont = getContfromURL(
    "$o{'urlStravaAPI'}/segments/starred?per_page=200&page=1", $token );
  my @L = convertJSONcont2Array($cont);
  return sortArrayHashRefsAbcAsc( 'name', @L );
} ## end sub fetchSegmentsStarred


sub fetchGearName {
  # fetch gear details from Strava
  # in: Token, gear_id
  # out: str: gear name
  my ( $token, $gear_id ) = @_;
  logSubStart('fetchGear');
  my $cont = getContfromURL( "$o{'urlStravaAPI'}/gear/$gear_id", $token );
  my %h    = convertJSONcont2Hash($cont);
  return $h{'name'};    # name, brand_name, model_name, description, distance
} ## end sub fetchGearName


sub fetchSegment {
  # fetch segment
  # in: Token, segmentid
  # out: hash
  my ( $token, $segmentid ) = @_;
  logSubStart('fetchSegment');
  my $cont
      = getContfromURL( "$o{'urlStravaAPI'}/segments/$segmentid", $token );
  my %h = convertJSONcont2Hash($cont);
  return %h;
} ## end sub fetchSegment


sub fetchSegmentRecord {
  # fetch leaderboard rank 1
  # in: Token, segmentid
  # out: count of athlets, time of rank 1
  my ( $token, $segmentid ) = @_;
  logSubStart('fetchSegmentRecord');
  my $cont
      = getContfromURL(
    "$o{'urlStravaAPI'}/segments/$segmentid/leaderboard?per_page=1&page=1",
    $token );
  my %h           = convertJSONcont2Hash($cont);
  my $entry_count = $h{"entry_count"};
  my $record_time = $h{"entries"}[0]{"elapsed_time"};
  return ( $entry_count, $record_time );
} ## end sub fetchSegmentRecord


sub fetchSegmentLeaderboard {
  my ( $token, $segment_id, $date_range, $club_id, $gender, $age_group ) = @_;
  logSubStart('fetchSegmentLeaderboard');
  # validate date_range
  $date_range = ""
      unless grep { $date_range eq $_ }
      qw (this_year this_month this_week today);
  $club_id = "" if $club_id == 0;
  my $page        = 1;
  my $lastpage    = 0;
  my $entry_count = 0;
  my @list;
  if    ( $gender eq 'men' )   { $gender = 'M'; }
  elsif ( $gender eq 'women' ) { $gender = 'F'; }
  else                         { $gender = ''; }

  $age_group = '' if ( $age_group eq 'all_age' );

  while ( $lastpage != 1 and $page <= 10 ) {
    my $url
        = "$o{ 'urlStravaAPI' }/segments/$segment_id/leaderboard?per_page=200&following=false&gender=$gender&age_group=$age_group&date_range=$date_range&club_id=$club_id&page=$page";
    my $cont = getContfromURL( $url, $token );
    my %h    = convertJSONcont2Hash($cont);

    $entry_count = $h{"entry_count"} if $entry_count == 0;
    my @entries_this_page = @{ $h{"entries"} };
    $lastpage = 1 if ( $#entries_this_page < 200 );
    foreach my $hashref (@entries_this_page) {
      my %h2      = %{$hashref};
      my $listref = [
        $h2{"rank"},         $h2{"elapsed_time"},
        $h2{"athlete_name"}, formatDate( $h2{"start_date_local"}, 'date' )
      ];
      push( @list, $listref );
    } ## end foreach my $hashref (@entries_this_page)

    # {
    #   'start_date_local' =&gt; '2019-02-28T15:08:36Z',
    #   'start_date' =&gt; '2019-02-28T14:08:36Z',
    #   'rank' =&gt; 182,
    #   'moving_time' =&gt; 133,
    #   'elapsed_time' =&gt; 133,
    #   'athlete_name' =&gt; 'xxxx'
    # };

    $page += 1;

  } ## end while ( $lastpage != 1 and...)
  # print Dumper @list;
  return @list;
} ## end sub fetchSegmentLeaderboard


sub fetchClubs {
  # TODO: caching via $s{ 'pathToClubsHashDump' }
  my ($token) = @_;
  logSubStart('fetchClubs');
  my @list;

  my $url  = "$o{ 'urlStravaAPI' }/athlete/clubs?per_page=200";
  my $cont = getContfromURL( $url, $token );
  my @l    = convertJSONcont2Array($cont);
  foreach my $hashref (@l) {
    my %h2      = %{$hashref};
    my $listref = [
      $h2{"id"},         $h2{"name"}, $h2{"member_count"},
      $h2{"sport_type"}, $h2{"city"}
    ];
    push( @list, $listref );
  } ## end foreach my $hashref (@l)
  return @list;
} ## end sub fetchClubs


sub formatDate {
  # convert 2019-05-16T14:18:00Z -> 2019-05-16 14:18:00
  my ( $date, $format ) = @_;
  logSubStart('formatDate');
  if ( $format eq 'datetime' ) {
    $date =~ s/^(\d{4}\-\d{2}\-\d{2})T(\d{2}:\d{2}:\d{2})Z$/$1 $2/;
  }
  elsif ( $format eq 'date' ) {
    $date =~ s/^(\d{4}\-\d{2}\-\d{2})T(\d{2}:\d{2}:\d{2})Z$/$1/;
  }
  else {
    die "format '$format' unknown";
  }

  return $date;
} ## end sub formatDate


sub secToMinSec {
  # convert 123s -> 02:03
  my ($sek) = @_;
  logSubStart('secToMinSec');
  my $minDec = $sek / 60;
  my $m      = int($minDec);
  my $s      = ( $minDec - $m ) * 60;
  return sprintf "%02d:%02d", $m, $s;
} ## end sub secToMinSec


sub activityUrl {
# in: activity ID, name
# out: <a href="https://www.strava.com/activities/<id>" target="_blank"><name></a>
  my ( $id, $name ) = @_;
  return
        '<a href="https://www.strava.com/activities/'
      . $id
      . '" target="_blank">'
      . $name . '</a>';
} ## end sub activityUrl


sub htmlPrintHeader {
  # print html header using $cgi->header and $cgi->start_html
  # in: $title, can be ""
  #     if $printNavi == 0 -> no navi and title are printed
  my ( $cgi, $title ) = @_;
  my $titleLong;
  logSubStart('htmlPrintHeader');
  if ( $title eq '' ) {
    $title     = "Torben\'s Strava Äpp";
    $titleLong = $title;
  }
  else {
    $titleLong = "Torben\'s Strava Äpp - $title";
  }
  # print html header
  print $cgi->header(
    -type    => 'text/html',
    -charset => 'utf-8'
  );
  my $html = $cgi->start_html(
    -title => $titleLong,
    -meta  => { 'author' => 'Torben Menke' }
        # ,-author=>'Torben Menke' # generates mailto:
    ,
    -style => { -src => [ '/style.css', './style-strava.css' ] }
        #    -style => { -src => './style-strava.css' }
  );
  # CGI.pm doesn't support HTML5 DTD; replace the one it puts in.
  $html =~ s{<!DOCTYPE.*?>}{<!DOCTYPE html>}s;
  $html =~ s{ */>}{>}sg;
  say $html;
  say "<h1_title><h1>$title</h1></h1_title>";
  return;
} ## end sub htmlPrintHeader


sub htmlPrintFooter {
  # print html footer using $cgi->end_html and close main div
  # in: $cgi
  my ($cgi) = @_;
  logSubStart('htmlPrintFooter');
  say '</div>';
  say $cgi->end_html;
} ## end sub htmlPrintFooter


sub htmlPrintNavigation {
  # prints the menu of available features
  # reads $session from %s
  logSubStart('htmlPrintNavigation');
  say '<div id="mySidenav" class="sidenav">';
  # my $buttonlayout = 'style="height:44px; width:200px"';
  my $missingActivityCacheDisablesButton
      = -f $s{'pathToActivityListHashDump'} ? '' : ' disabled="disabled"';
  my $missingScopeActivityWriteDisablesButton
      = $s{'scope'} =~ m/activity:write/ ? '' : ' disabled="disabled"';

  my $countActCached = 0;
  if ( -f $s{'pathToActivityListHashDump'} ) {
    my @allActivityHashes = @{ retrieve( $s{'pathToActivityListHashDump'} ) }
        ;    # retrieve data from file (as ref)
    $countActCached = 1 + $#allActivityHashes;
    undef @allActivityHashes;
  } ## end if ( -f $s{'pathToActivityListHashDump'...})
  say
      "<p style=\"text-align:center\"><small>cached activities: $countActCached</small></p>";

  say '
	<form action="activityListCaching.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavCacheAll" value="Cache Activities All"
  title="download and cache list of all activities, required for other features
(be patient, takes a little while, &asymp;1 min per 1000 activities)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	<input type="hidden" name="year" value="all">
	</form> ';

  say '
	<form action="activityListCaching.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavCacheYear" value="Cache Activities Year"
  title="download and cache list of activities per year, required for other features
(use if caching of all activities results in a timeout)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

# 17.11.2020: Strava disabled this feature
#  say '
#	<form action="segmentLeaderboard.pl" method="post">
#	<input type="submit" name="submitFromNav" class="navButton" id="btnSegmentLeaderboard" value="Segment Leaderboard"
#  title="Fetch a segment\'s Leaderboard">
#	<input type="hidden" name="session" value="' . $s{ 'session' } . '">
#	</form>';
#
#
  say '
	<form action="activityTable.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActTable" value="Activity Table" '
      . $missingActivityCacheDisablesButton . '
  title="display statistics of your activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityStats2.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActStats2" value="Activity Statistics V2" '
      . $missingActivityCacheDisablesButton . '
  title="display statistics of your activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityStats.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActStats" value="Activity Statistics V1" '
      . $missingActivityCacheDisablesButton . '
  title="display statistics of your activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityTop10V2.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActTop10" value="Activity Top10 V2" '
      . $missingActivityCacheDisablesButton . '
  title="display Top10 activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';
  say '
	<form action="activityTop10.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActTop10" value="Activity Top10 V1" '
      . $missingActivityCacheDisablesButton . '
  title="display Top10 activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activitySearch.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActSearch" value="Search For Activity" '
      . $missingActivityCacheDisablesButton . '
  title="searching for an activity, based on multiple criteria
(requires caching first)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityExcelExport.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActListExcel" value="Activity Excel Export" '
      . $missingActivityCacheDisablesButton . '
  title="generate/export activity Excel report
(requires caching first)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityCalExport.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActCalExcel" value="Activity Calendar Export" '
      . $missingActivityCacheDisablesButton . '
  title="generate/export activity Excel report
(requires caching first)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>

';
  say '
	<form action="activityExcelImport.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActListExcelImport" value="Activity Excel Import" '
      . $missingScopeActivityWriteDisablesButton . '
  title="generate/export activity Excel report
(requires caching first)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>
';
  say '
	<form action="activityList.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActList" value="Activity List " '
      . $missingActivityCacheDisablesButton . '
  title="list all activities
(requires caching first)" >
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="activityModify.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavActModify" value="Modify Activities" '
      . $missingScopeActivityWriteDisablesButton . '
  title="bulk modify activities\' meta data
(requires write scope)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="frequent-start-end.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavFreqStartEnd" value="Frequent Locations" '
      . $missingActivityCacheDisablesButton . '
  title="list frequently used start and end activity locations
(requires caching first)">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="knownLocations.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavEditKnownLoc" value="Edit Known Locations"
  title="edit list of known start/end locations to enrich Excel activity report">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="segments.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnSegments" value="Starred Segments"
  title="Fetch starred segments">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="clearCache.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavClearCache" value="Clear Cache"
  title="delete cached activity data">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="/contact.php?origin=strava" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavContact" value="Contact"
  title="contact me for bug reports and feature requests">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say '
	<form action="deauth.pl" method="post">
	<input type="submit" name="submitFromNav" class="navButton" id="btnNavQuit" value="Quit"
  title="quit session: delete the temporary data
and deauthorize this app from your Strava account">
	<input type="hidden" name="session" value="' . $s{'session'} . '">
	</form>';

  say
      '<p><img src="./strava-resources/api_logo_pwrdBy_strava_stack_light.svg" alt="Powered by Strava" height="86"></p>';

  say '</div>';
  say '<div class="main">';

  return;
} ## end sub htmlPrintNavigation


sub send_mail {
# in: $subject, $body, $to_address
# out: nothing
# sends an email
# correct utf-8 encoding for body
# subject encoding not 100% correct, since something link =?utf-8?B? should be added, but I couldn't get it working. Thunderbird and K9-Mail accept the subject, so it should be fine for me

  my ( $subject, $body, $to_address ) = @_;
  logSubStart('send_mail');
  # V1: sendmail
  # $subject = encode( 'UTF-8', $subject );
  # # $body    = encode( 'UTF-8', $body ); # no need for conversion here
  # my $mailprog = '/usr/lib/sendmail';
  # open( MAIL, "|$mailprog -t" ) || print STDERR "Mail-Error\n";
  # print MAIL "To: $to_address\n";
  # print MAIL "Subject: [Strava] $subject\n";    # =?utf-8?B?
  # print MAIL "Content-Type: text/plain; charset=\"utf-8\"";
  # print MAIL "\n$body";                         # \n starts body
  # close( MAIL );

  # V2: via my Mail_Daemon
  insertNewEMail( $to_address, $subject, $body, '' );
  return;
} ## end sub send_mail


sub insertNewEMail {
  # This is a copy of Mail-Daemon/insert.pl
  use lib ('/var/www/virtual/entorb/perl5/lib/perl5');
  my ( $send_to, $subject, $body, $send_from ) = @_;   # , $send_cc, $send_bcc

  my $PATH = "/var/www/virtual/entorb/mail-daemon/outbox.db";
  use DBI;
  my $dbh = DBI->connect( "dbi:SQLite:dbname=$PATH", "", "" );
  $dbh->{AutoCommit} = 0;

  my $sth
      = $dbh->prepare(
    "INSERT INTO outbox(send_to, subject, body, send_from, send_cc, send_bcc, date_created, date_sent) VALUES (?, ?, ?, ?, '', '', CURRENT_TIMESTAMP, NULL)"
      );
  $sth->bind_param( 1, $send_to,   DBI::SQL_VARCHAR );
  $sth->bind_param( 2, $subject,   DBI::SQL_VARCHAR );
  $sth->bind_param( 3, $body,      DBI::SQL_VARCHAR );
  $sth->bind_param( 4, $send_from, DBI::SQL_VARCHAR );
  $sth->execute;
  $dbh->commit;
} ## end sub insertNewEMail

# sub convertDate4Excel {
# # 2018-08-21T08:14:53Z -> 21.08.2018 08:14:53
#     my ($s) = @_;
#     if ( not $s =~ m/^(\d{4})\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/ ) {
#         say "WARN: '$s' does not match yyyy-mm-ddThh:mm:ssZ";
#         return $s;
#     }
#     $s = "$3.$2.$1";#  $4:$5:$6
#     return $s;
# }


sub excel_autofit_columns {
# from https://metacpan.org/pod/Spreadsheet::WriteExcel::Examples#Example:-autofit.pl
# Adjust the column widths to fit the longest string in the column.
  my $worksheet = shift;
  logSubStart('excel_autofit_columns');
  my $col = 0;
  for my $width ( @{ $worksheet->{__col_widths} } ) {
    $worksheet->set_column( $col, $col, $width ) if $width;
    $col++;
  }
  return;
} ## end sub excel_autofit_columns


sub excel_store_excel_string_widths {
# from https://metacpan.org/pod/Spreadsheet::WriteExcel::Examples#Example:-autofit.pl
# The following function is a callback that was added via add_write_handler()
# above. It modifies the write() function so that it stores the maximum
# unwrapped width of a string in a column.
  my $worksheet = shift;
  my $col       = $_[1];
  my $token     = $_[2];
  # logSubStart ('excel_store_excel_string_widths');

  # Ignore some tokens that we aren't interested in.
  return if not defined $token;       # Ignore undefs.
  return if $token eq '';             # Ignore blank cells.
  return if ref $token eq 'ARRAY';    # Ignore array refs.
  return if $token =~ /^=/;           # Ignore formula

  # Ignore numbers
  return if $token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

  # Ignore various internal and external hyperlinks. In a real scenario
  # you may wish to track the length of the optional strings used with
  # urls.
  return if $token =~ m{^[fh]tt?ps?://};
  return if $token =~ m{^mailto:};
  return if $token =~ m{^(?:in|ex)ternal:};

  # We store the string width as data in the Worksheet object. We use
  # a double underscore key name to avoid conflicts with future names.
  #
  my $old_width          = $worksheet->{__col_widths}->[$col];
  my $excel_string_width = excel_string_width($token);

  if ( not defined $old_width or $excel_string_width > $old_width ) {

    # You may wish to set a minimum column width as follows.
    #return undef if $excel_string_width < 10;
    $worksheet->{__col_widths}->[$col] = $excel_string_width;
  } ## end if ( not defined $old_width...)

  # Return control to write();
  return undef;
} ## end sub excel_store_excel_string_widths


sub excel_string_width {
# from https://metacpan.org/pod/Spreadsheet::WriteExcel::Examples#Example:-autofit.pl
# Very simple conversion between string length and string width for Arial 10.
# See below for a more sophisticated method.
# logSubStart ('excel_string_width');
  my $len = 1.0 * length $_[0];
  if ( $len > 64 ) {
    $len = 64;
  }
  return $len;
} ## end sub excel_string_width


sub geoBoxesFromDataFile {
# param file containing lines of: $continent, $country, $subdivision, $city, $latitude, $longitude (each without , ; in it)
# comment lines are ignored
# first line is ignored (header)
  my ($fileIn) = @_;
  logSubStart('geoBoxesFromDataFile');
  my %boxes;
  open my $fhIn, '<:encoding(UTF-8)', $fileIn
      or die "ERROR: Can't read from file '$fileIn': $!";
  $/ = "\n";       # linux end of line
  $_ = <$fhIn>;    # header line
  chomp $_;

  while ( my $line = <$fhIn> ) {
    chomp $line;
    next if substr( $line, 0, 1 ) eq '#';    # remove comments
    my ( $continent, $country, $subdivision, $city, $latitude, $longitude )
        = split ',', $line;
    $latitude  += 0;
    $longitude += 0;
    my $name = "$continent-$country-$subdivision-$city";
    geoBoxes1DegAdd( \%boxes, $latitude, $longitude, $name );
  } ## end while ( my $line = <$fhIn>)
  close $fhIn;
  return %boxes;
} ## end sub geoBoxesFromDataFile


sub geoBoxes1DegAdd {
  # param:
  # hashref to boxes
  # lat, lon, name of item
  my ( $refBoxes, $latitude, $longitude, $name ) = @_;
# logSubStart( 'geoBoxes1DegAdd' );
# $geoBoxOffset: sub-degrees to add and substract to location to find boxes. range: 0..1
  my $geoBoxOffset = 0.5;
  $name =~ s/[,;]+//g;    # remove , and ;
  my $s = "$latitude,$longitude,$name";
  my ( $lat0, $lon0 ) = ( int($latitude), int($longitude) );
  # lat
  my $lat1 = int( $latitude - $geoBoxOffset );
  if ( $lat1 == $lat0 ) {    # same box, so try + instead
    $lat1 = int( $latitude + $geoBoxOffset );
    if ( $lat1 == $lat0 ) {
      $lat1 = undef;         # still same box, so must be close to center
    }
  } ## end if ( $lat1 == $lat0 )
  if ( defined($lat1) and ( $lat1 > 90 or $lat1 < -90 ) ) {
    $lat1 = undef;
  }
  # lon
  my $lon1 = int( $longitude - $geoBoxOffset );
  if ( $lon1 == $lon0 ) {    # same box, so try + instead
    $lon1 = int( $longitude + $geoBoxOffset );
    if ( $lon1 == $lon0 ) {
      $lon1 = undef;         # still same box, so must be close to center
    }
  } ## end if ( $lon1 == $lon0 )
  if ( defined($lon1) and ( $lon1 > 90 or $lon1 < -90 ) ) {
    $lon1 = undef;
  }
  $refBoxes->{$lat0}{$lon0} .= ";$s";
  $refBoxes->{$lat1}{$lon0} .= ";$s" if defined $lat1;
  $refBoxes->{$lat1}{$lon1} .= ";$s" if defined $lat1 and defined $lon1;
  $refBoxes->{$lat0}{$lon1} .= ";$s" if defined $lon1;
} ## end sub geoBoxes1DegAdd


sub geoBoxesFetchClosestEntry {
  # in: hash ref to geoBoxes, lat and lon of location to search
  # returns location name and distance in km
  # returns none, 999 if no match
  my ( $refBoxes, $lat, $lon ) = @_;
  logSubStart('geoBoxesFetchClosestEntry');
  my $minDist     = 999;
  my $minDistName = 'none';
  return ( $minDistName, $minDist )
      if ( not defined $refBoxes->{ int $lat }{ int $lon } );

  my @kandidaten = split ';', $refBoxes->{ int $lat }{ int $lon };
  shift @kandidaten;    # remove first empty one
                        # say Dumper @kandidaten;
  foreach my $s (@kandidaten) {
    my ( $citylat, $citylon, $name ) = split ',', $s;
    my $dist = geoDistance( $lat, $lon, $citylat, $citylon );
    if ( $dist < $minDist ) {
      $minDist     = $dist;
      $minDistName = $name;
    }
  } ## end foreach my $s (@kandidaten)
  return ( $minDistName, $minDist );
} ## end sub geoBoxesFetchClosestEntry


sub geoDistance {
# from  https://www.geodatasource.com/developers/perl
# This routine calculates the distance between two points (given the latitude/longitude of those points).
# Definitions:
#  South latitudes are negative, east longitudes are positive
# Passed to function:
#  lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)
#  lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)
  my ( $lat1, $lon1, $lat2, $lon2 ) = @_;
  # logSubStart ('geoDistance');
  # TM: always use km
  # my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;
  my $dist
      = sin( deg2rad($lat1) ) * sin( deg2rad($lat2) )
      + cos( deg2rad($lat1) ) * cos( deg2rad($lat2) ) *
      cos( deg2rad( $lon1 - $lon2 ) );
  $dist = rad2deg( acos($dist) );
  $dist = $dist * 60 * 1.1515 * 1.609344;
  # $dist = $dist * 60 * 1.1515;
  # if ($unit eq "K") { #km
  # $dist = $dist * 1.609344;
  # } elsif ($unit eq "N") { # Nautic Miles
  # $dist = $dist * 0.8684;
  # }
  return ($dist);
} ## end sub geoDistance


sub acos {
  # from  https://www.geodatasource.com/developers/perl
  # This function get the arccos function using arctan function
  my ($rad) = @_;
  # logSubStart ('acos');
  if ( $rad**2 > 1 ) {
    return 0.0;
  }
  else {
    return atan2( sqrt( 1 - $rad**2 ), $rad );
  }
} ## end sub acos


sub deg2rad {
  # from  https://www.geodatasource.com/developers/perl
  # This function converts decimal degrees to radians
  my ($deg) = @_;
  # logSubStart ('deg2rad');
  return ( $deg * PI / 180 );
} ## end sub deg2rad


sub rad2deg {
  # from  https://www.geodatasource.com/developers/perl
  # This function converts radians to decimal degrees
  my ($rad) = @_;
  # logSubStart ('rad2deg');
  return ( $rad * 180 / PI );
} ## end sub rad2deg

#
1;    # Module needs to return 1
