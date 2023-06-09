#!/usr/bin/env perl
# alt: !/usr/bin/perl

# by Torben Menke https://entorb.net

# DESCRIPTION

# TODO

# IDEAS
# Use an algorithm from here: https://towardsdatascience.com/the-5-clustering-algorithms-data-scientists-need-to-know-a36d136ef68
# Zahl der Locations lässt sich verringern, wenn diese gerundet werden, aber Häufigkeit
# as we only have 2 digits for lat and lon, I should add caching

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# # Modules: Perl Standard
# use Encode qw(encode decode);
# use open ":encoding(UFT-8)";    # for all files
# my $encodingSTDOUT = 'CP850';   # Windows/DOS: 'CP850'; Linux: UTF-8
# use Time::HiRes qw(time);       # time in ms

# Modules: Web
use CGI;
my $cgi = CGI->new;
#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: File Access
use File::Basename;    # for basename, dirname, fileparse
use File::Path qw(make_path remove_tree);
use Storable;          # read/write hash from file system

# Modules: My Strava Module Lib
use lib ('.');
use lib ('/var/www/virtual/entorb/perl5/lib/perl5');
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web"
    ;                  # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;                  # at entorb.net some modules require use local::lib!!!

my $runLocal = 0;      # TODO: am I running local or on entorb.net
if ( $runLocal == 0 ) {
  TMsStrava::htmlPrintHeader( $cgi, 'Frequent start/end locations' );
  TMsStrava::initSessionVariables( $cgi->param("session") );
  TMsStrava::htmlPrintNavigation();
}
else {
  my $session = '-e1lFk8GfN4IuXse-wYFHQ';
  $o{'tmpDataFolderBase'} = './temp-data';
  TMsStrava::initSessionVariables($session);
  TMsStrava::htmlPrintNavigation();

} ## end else [ if ( $runLocal == 0 ) ]

my @ListeDerPunkte;
my @ListeDerPunkteStart;
my @ListeDerPunkteEnd;
my $maxDistance                        = 0.75;    # km
my $maxLocationsToCheckForFrequentOnes = 1000;    # TODO: Test

my $debugPrintTiming = 0;                         # TODO

# my @matrix = (
# ['q','w', undef() ,'r','t'],
# ['q','w','e','r','t'],
# ['q','w','e','r','t'],
# ['a','s','d','f','g'],
# ['q','w','e','r','t']
# );
# print Dumper @matrix;
# @matrix = removeRowColFromMatrix(2,@matrix);
# print Dumper @matrix and die;

# my ($x1,$y1,$x2,$y2);
# $x1 = 46.110000;
# $y1 = 8.846000;
# $x2 = $x1 + 0.0001;
# $y2 = $y1 + 0.0001;
# # Runden auf 4 Kommastellen entspricht in Erlangen 13.5m
# # $x2 = 0 + sprintf("%.4f",$x1);
# # $y2 = 0 + sprintf("%.4f",$y1);
# say dist($x1,$y1,$x2,$y2);
# die;

my $tsStart = time;

my @allActivityHashes = ();

# for Local use
# my @L = <../Strava-Web/temp-data/KwdWm6bdssPjUXIDpPvbOw/activityList/per_page-200*.json>;
# my @allActivityHashes =
# reverse TMsStrava::convertJsonFilesToArrayOfHashes(@L);    #

# if not already done, fetchActivityList, 200 per page into dir activityList

unless ( -f $s{'pathToActivityListHashDump'} ) {
  die("E: activity cache missing");
}
#   TMsStrava::logIt( "downloading data files" );
#   TMsStrava::fetchActivityList( $s{ 'token' }, 200, 0 );    # max 200 per page/json file, max X days past
#   # TMsStrava::fetchActivityList( $s{'token'}, 200, 365 );    # max 200 per page/json file, max X days past
#   # fetch all of the filenames
#   TMsStrava::logIt( "convertJsonFilesToArrayOfHashes and write .dmp to filesystem" );
#   my @L = <$s{'tmpDataFolder'}/activityList/per_page-200*.json>;
#   @allActivityHashes = reverse TMsStrava::convertJsonFilesToArrayOfHashes( @L );    # reverse here, since I now use parameter "after" in fetchActivityList, which leads to ASC sorting, which is not what I want for the display
#   # write hash to file-system
#   store \@allActivityHashes, $s{ 'pathToActivityListHashDump' };
# } else {
TMsStrava::logIt("reading activity data from .dmp file");
my $ref = retrieve( $s{'pathToActivityListHashDump'} );
# retrieve data from file (as ref)
@allActivityHashes = @{$ref};    # convert arrayref to array
# } ## end else

# remove the locations that are already known
my @knownLocations = TMsStrava::getKnownLocationsOfUser();
# @knownLocations = ();

foreach my $activityRef (@allActivityHashes) {
  my %h = %{$activityRef};
  next unless defined $h{'start_latlng'};
  my @a        = @{ $h{'start_latlng'} };
  my $iKnowYou = 0;
  foreach my $kl (@knownLocations) {
    my @kl         = @{$kl};
    my $istNachbar = pruefeNachbar( $a[0], $a[1], $kl[0], $kl[1] );
    if ( defined $istNachbar ) {
      $iKnowYou = 1;
      last;
    }
  } ## end foreach my $kl (@knownLocations)
  if ( $iKnowYou == 0 ) {
    push @ListeDerPunkteStart, [ $a[0], $a[1] ];
  }

  next unless defined $h{'end_latlng'};
  @a        = @{ $h{'end_latlng'} };
  $iKnowYou = 0;
  foreach my $kl (@knownLocations) {
    my @kl         = @{$kl};
    my $istNachbar = pruefeNachbar( $a[0], $a[1], $kl[0], $kl[1] );
    if ( defined $istNachbar ) {
      $iKnowYou = 1;
      last;
    }
  } ## end foreach my $kl (@knownLocations)
  if ( $iKnowYou == 0 ) {
    push @ListeDerPunkteEnd, [ $a[0], $a[1] ];
  }
  last
      if ( $#ListeDerPunkteStart + 1 + $#ListeDerPunkteEnd + 1
    >= $maxLocationsToCheckForFrequentOnes );
} ## end foreach my $activityRef (@allActivityHashes)

# hier werden Start und End Punkte zusammen in eine Liste aller Punkte gefügt.
@ListeDerPunkte = @ListeDerPunkteStart;
push @ListeDerPunkte, @ListeDerPunkteEnd;
@ListeDerPunkteStart = undef;
@ListeDerPunkteEnd   = undef;
# say '<h1>List of frequently used start and end locations</h1>';
say "<p>"
    . ( $#ListeDerPunkte + 1 )
    . " not known start/end locations to check for cluster</p>";
say sprintf( "%.1fs after reading allActivityHashes", ( time - $tsStart ) )
    if $debugPrintTiming;

# # Idee: Zum Beschleunigen Koordinaten runden und Punkte zusammenfassen
# my %h;
# my @ListeDerPunkteGerundet = ();
# my @ListeDerHaeufigkeiten = ();
# # for (my $i=$#ListeDerPunkte;$i>=0;$i--) {
# for (my $i=0;$i<=$#ListeDerPunkte;$i++) {
# $_ = sprintf("%.4f %.4f", $ListeDerPunkte[$i][0], $ListeDerPunkte[$i][1]);
# $h{$_} ++; # Koordinaten in String Form als Schlüssel des %h
# }
# # by values, reverse
# foreach my $k ( sort { $h{$b} <=> $h{$a} } keys(%h)) {
# # last if $h{$k}==1;
# @_ = split ' ', $k;
# push @ListeDerPunkteGerundet, [$_[0],$_[1]];
# push @ListeDerHaeufigkeiten, $h{$k};
# }
# say "Es bleiben ".($#ListeDerPunkteGerundet+1)." gerundete Locations";

# alt: Lesen aus Datei
# my $fileIn = "start-unknown.txt";
# open(my $fhIn, '<:encoding(UTF-8)', $fileIn)
# or die "ERROR: Can't read from file '$fileIn': $!";
# while (my $line = <$fhIn>) {
# $line =~ m/^\[([\d\.]+), ([\d\.]+)\]\n?/ or die "no match";
# my ($lat,$lng) = ($1,$2);
# push @ListeDerPunkte, [$lat,$lng];
# }
# close $fhIn;
# # say ($ListeDerPunkte[2][0] . " " . $ListeDerPunkte[2][1]);
# # say $#ListeDerPunkte;
# # say (dist(0,0,1,1));

# my @MatrixDerDistanzen;
# $MatrixDerDistanzen[$#ListeDerPunkte][$#ListeDerPunkte] = undef()
my @MatrixDerNachbarn;
$MatrixDerNachbarn[$#ListeDerPunkte][$#ListeDerPunkte] = undef()
    ; # ensure that matrix has the same size as @ListeDerPunkte (at least for the last row)
my @AnzDerNachbarn = (0) x ( 1 + $#ListeDerPunkte );

# Distanz zwischen allen Punkten berechnen und für jeden Punkt die Anz der Nachbarn zählen
for ( my $i = 0; $i <= $#ListeDerPunkte; $i++ ) {
  for ( my $j = $i + 1; $j <= $#ListeDerPunkte; $j++ ) {
    my $istNachbar = pruefeNachbar(
      $ListeDerPunkte[$i][0], $ListeDerPunkte[$i][1],
      $ListeDerPunkte[$j][0], $ListeDerPunkte[$j][1]
    );
    if ( defined $istNachbar ) {
      $MatrixDerNachbarn[$i][$j] = $istNachbar;
      $MatrixDerNachbarn[$j][$i] = $istNachbar;
      $AnzDerNachbarn[$i]++;
      $AnzDerNachbarn[$j]++;
    } ## end if ( defined $istNachbar)
    # my $dist = dist(
    # $ListeDerPunkte[$i][0], $ListeDerPunkte[$i][1],
    # $ListeDerPunkte[$j][0], $ListeDerPunkte[$j][1]
    # );
    # if ( defined $dist and $dist < 5 ) {    # 5km hier als erster Filter
    # $MatrixDerDistanzen[$i][$j] = $dist;
    # $MatrixDerDistanzen[$j][$i] = $dist;
    # }
  } ## end for ( my $j = $i + 1; $j...)
} ## end for ( my $i = 0; $i <= ...)
say sprintf( "%.1fs after calc distances", ( time - $tsStart ) )
    if $debugPrintTiming;

# anzDerNachbarnErmitteln(); # initial bereits oben
removeLocationsWithoutNeighbors();
say sprintf( "%.1fs after init removeLocationsWithoutNeighbors",
  ( time - $tsStart ) )
    if $debugPrintTiming;
say "" . ( $#ListeDerPunkte + 1 ) . " Locations" if $debugPrintTiming;

# TODO: wie weiter?
# Einfachster Ansatz: Einen der Punkte mit den meisten Nachbarn nehmen, und aus dem und seinen Nachbarn einen Cluster definieren
# Dann den Cluster-Mittelwert bestimmen
# Was wenn mehrere andere genauso viele Nachbarn haben? -> vermutlich egal

say '<p>Clusters of unknown locations:</p>
<code>';
my $anzClustersFound = 0;

use List::Util qw( min max );    # or use List::MoreUtils qw( minmax );
while ( max(@AnzDerNachbarn) >= 5 ) {
  searchForCluster();
  $anzClustersFound++;

# Werte in @AnzDerNachbarn sind nun ggf nicht mehr korrekt, daher neu befüllen
  anzDerNachbarnErmitteln();
  removeLocationsWithoutNeighbors();
} ## end while ( max(@AnzDerNachbarn...))

if ( $anzClustersFound == 0 ) {
  say 'none<br/>';
}
say "</code>";
say sprintf( "Duration Total= %.1f", ( time - $tsStart ) )
    if $debugPrintTiming;

if ( $anzClustersFound > 0 ) {
  say
      '<p>You might like to copy them to your <a href="knownLocations.pl?session='
      . $s{'session'}
      . '">list of known locations</a> or check them at Google Maps or <a href="https://www.openstreetmap.org">OpenStreetmap</a></p>';
} ## end if ( $anzClustersFound...)

TMsStrava::htmlPrintFooter($cgi);

# say "Übrig bleiben: ";
# say Dumper \@ListeDerPunkte;

# welcher Punkte hat wie viele dichte Nachbarn
# for (my $i=0;$i<=$#ListeDerPunkte;$i++) {
#   my $anzNachbarn = 0;
#   for (my $j=0;$j<=$#ListeDerPunkte;$j++) {
#     next if not defined $MatrixDerDistanzen[$i][$j];
#     $anzNachbarn ++ if ($MatrixDerDistanzen[$i][$j] < $maxDistance)
#   }
#   say "$i $anzNachbarn";
# }


sub anzDerNachbarnErmitteln {

  # @AnzDerNachbarn aus @MatrixDerDistanzen ermitteln
  # initial wird mit 0 befuellt
  # es wird bei $dist < $maxDistance gezählt
  @AnzDerNachbarn = (0) x ( 1 + $#ListeDerPunkte );    # fill by 0
  for ( my $i = 0; $i <= $#ListeDerPunkte; $i++ ) {
    for ( my $j = $i + 1; $j <= $#ListeDerPunkte; $j++ ) {
      # my $dist = $MatrixDerDistanzen[$i][$j];
      my $istNachbar = $MatrixDerNachbarn[$i][$j];
      if ( defined $istNachbar ) {
        $AnzDerNachbarn[$i]++;
        $AnzDerNachbarn[$j]++;
      }
    } ## end for ( my $j = $i + 1; $j...)
  } ## end for ( my $i = 0; $i <= ...)
} ## end sub anzDerNachbarnErmitteln


sub removeLocationsWithoutNeighbors {

# Locations mit weniger als 2 Nachbarn aus der Liste raus, um Rechenzeit zu sparen.
# Working on @ListeDerPunkte, @AnzDerNachbarn, @MatrixDerDistanzen
# Bringt nur bei der Suche nach vielen Clustern einen Performance Gewinn, da dieses Löschen recht langsam ist.
  for ( my $i = $#ListeDerPunkte; $i >= 0; $i-- ) {
    if ( $AnzDerNachbarn[$i] <= 1 ) {    # 0 oder 1
      splice @ListeDerPunkte, $i, 1;     # remove it
      splice @AnzDerNachbarn, $i, 1;     # remove it
       # @MatrixDerDistanzen = removeRowColFromMatrix( $i, @MatrixDerDistanzen );
      @MatrixDerNachbarn = removeRowColFromMatrix( $i, @MatrixDerNachbarn );
    } ## end if ( $AnzDerNachbarn[$i...])
  } ## end for ( my $i = $#ListeDerPunkte...)

# say sprintf ("%.1fs after removing locations without neighbors", (time-$tsStart));
} ## end sub removeLocationsWithoutNeighbors


sub searchForCluster {

  # Suche die Location mit den meisten Nachbarn
  my $meisteNachbarnAnz   = 0;
  my $meisteNachbarnIndex = 0;
  for ( my $i = 0; $i <= $#ListeDerPunkte; $i++ ) {
    if ( $AnzDerNachbarn[$i] > $meisteNachbarnAnz ) {
      $meisteNachbarnAnz   = $AnzDerNachbarn[$i];
      $meisteNachbarnIndex = $i;
    }
  } ## end for ( my $i = 0; $i <= ...)
# say "Das Cluster um index $meisteNachbarnIndex beinhaltet $meisteNachbarnAnz Nachbarn.";
# say sprintf( "%.1fs after searching for cluster members", ( time - $tsStart ) );

  # welche sind es?
  my @ImCluster = ();
  for ( my $j = 0; $j <= $#ListeDerPunkte; $j++ ) {
    # my $dist = $MatrixDerDistanzen[$meisteNachbarnIndex][$j];
    my $istNachbar = $MatrixDerNachbarn[$meisteNachbarnIndex][$j];
    if ( defined $istNachbar ) {
      push @ImCluster, $j;
    }
  } ## end for ( my $j = 0; $j <= ...)
  # say "Es sind diese: @ImCluster";
  # foreach my $i (@ImCluster) {
  # say "$i  $ListeDerPunkte[$i][0]  $ListeDerPunkte[$i][1]";
  # }

  # Schwerpunkt bestimmen. Dazu vektoriell Summe bilden und durch Anz teilen.
  my ( $clusterSchwerpunktX, $clusterSchwerpunktY ) = ( 0, 0 );
  foreach my $i (@ImCluster) {
    $clusterSchwerpunktX += $ListeDerPunkte[$i][0];
    $clusterSchwerpunktY += $ListeDerPunkte[$i][1];
  }
  $clusterSchwerpunktX /= ( 1 + $#ImCluster );
  $clusterSchwerpunktY /= ( 1 + $#ImCluster );
  $clusterSchwerpunktX = sprintf '%.6f', $clusterSchwerpunktX;
  $clusterSchwerpunktY = sprintf '%.6f', $clusterSchwerpunktY;

  say sprintf(
    "<a href=\"https://maps.google.com/?q=$clusterSchwerpunktX,$clusterSchwerpunktY\" target=\"_blank\">%02d: $clusterSchwerpunktX $clusterSchwerpunktY %dx</a><br/>",
    ( 1 + $anzClustersFound ),
    ( 1 + $#ImCluster )
  );

  # entfernen dieser aus den Orignal Listen
  foreach my $i ( reverse @ImCluster ) {
    splice @ListeDerPunkte, $i, 1;    # remove it
    splice @AnzDerNachbarn, $i, 1;    # remove it
     # @MatrixDerDistanzen = removeRowColFromMatrix( $i, @MatrixDerDistanzen );
    @MatrixDerNachbarn = removeRowColFromMatrix( $i, @MatrixDerNachbarn );
  } ## end foreach my $i ( reverse @ImCluster)
  say sprintf( "%.01fs", ( time - $tsStart ) ) if $debugPrintTiming;
} ## end sub searchForCluster


sub pruefeNachbar {
  my ( $x1, $y1, $x2, $y2 ) = @_;
  return undef()
      if ( abs( $x1 - $x2 ) > 0.1 or abs( $y1 - $y2 ) > 0.1 )
      ;    # an angle of 0.1 is > 10km
  my $geodist = TMsStrava::geoDistance( $x1, $y1, $x2, $y2 );
  if ( $geodist < $maxDistance ) {
    return 1;
  }
  else {
    return undef();
  }
} ## end sub pruefeNachbar


sub dist {
  my ( $x1, $y1, $x2, $y2 ) = @_;

# die detail-kakulation kann man sich sparen wenn die Koordinaten offensichtlich weit auseinander liegen
  return undef()
      if ( abs( $x1 - $x2 ) > 0.1 or abs( $y1 - $y2 ) > 0.1 )
      ;    # an angle of 0.1 is > 10km
           # my $dx = $x2-$x1;
           # my $dy = $y2-$y1;
           # my $sqrtdist = sqrt($dx*$dx + $dy*$dy);
  my $geodist = TMsStrava::geoDistance( $x1, $y1, $x2, $y2 );

  # say "sqrtdist=$sqrtdist  geodist=$geodist";
  # return (sqrt($dx*$dx + $dy*$dy));
  return $geodist;
} ## end sub dist

# TODO: remove multiple columns from matrix: first the rows (fast) than the columns (slow)
sub removeRowColFromMatrix {

  # remove row $i and col $i form symmetric matrix
  # in: $i, @matrix
  # out: @matrix (with 1 row and 1 column less
  my ( $i, @matrix ) = @_;

  # remove row $i
  splice @matrix, $i, 1;

  # remove col $i
  foreach my $row (@matrix) {
    next unless defined $row;
    my @L = @{$row};
    next if ( $#L < $i );
    splice @L, $i, 1;
    $row = \@L;
  } ## end foreach my $row (@matrix)
  return @matrix;
} ## end sub removeRowColFromMatrix

