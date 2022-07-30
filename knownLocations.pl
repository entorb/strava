#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# edit known locations stored as .txt
# sort and cleanup on write
# format "$lat $lon $loc\n", sorted by $loc name

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

TMsStrava::htmlPrintHeader( $cgi, 'Known locations');
TMsStrava::initSessionVariables( $cgi->param( "session" ) );
TMsStrava::htmlPrintNavigation();

say "<p>Privacy warning: This data is stored on the server until you replace it by an empty list.</p>";

my @knownLocations;

# submit: write new contents
# if contents is empty -> delete file
if ( $cgi->param( 'submit' ) ) {
  my $s = $cgi->param( 'knownLocations' );
  if ( $s =~ m/^\s*$/s ) {    # knownLocations is empty -> delete file
    if ( -f $s{ 'fileKnownLocations' } ) {
      unlink $s{ 'fileKnownLocations' };    #
      TMsStrava::logIt("deleted known locations file");
      say "<p>Deleted your known locations</p>";
    }
  } else {    # write to file
    my $s = decode( 'UTF-8', $cgi->param( 'knownLocations' ) );
    my @formdata = split /(\r?\n|\r)/, $s;
    my %h;    # temp storage for sorting
    foreach my $line ( @formdata ) {
      # cleanup unwanted chars like ","
      next unless $line =~ m/^[^\d\-]*([\d\-\.]+)[^\d\-]*([\d\-\.]+) (.*)\r?\n?$/;
      my ( $lat, $lon, $loc ) = ( $1, $2, $3 );
      $loc =~ s/(^\s*|\s*$)//g;    # trim spaces from ends
      $loc =~ s/\s+//;             # whitespaces -> ""
      $h{ $loc } = [ $lat, $lon ];
    }
    my @L = sort keys( %h );
    foreach my $k ( @L ) {
      push @knownLocations, join( " ", @{ $h{ $k } } ) . " $k";    # $lat $lon $loc, sorted by $loc name
    }
    open( my $fhOut, '>:encoding(UTF-8)', $s{ 'fileKnownLocations' } )
        or die( "ERROR: Can't write to file" );
    print $fhOut join( "\n", @knownLocations );
    close $fhOut;
    TMsStrava::logIt("wrote known locations to file");
  }
  # remove excel export after modification of know places
  foreach my $file ( <$s{'tmpDownloadFolder'}/*.xlsx> ) {
    unlink $file;
    TMsStrava::logIt("deleted Excel download files after modification of known locations");
  }
}    # if submit

# the list is displayed wether or not the form is submittet and wether or not a user's location file is present

# Read known locations from file $stravaUserID.txt
# format of file: "$lat $lon "descripting (without spaces)\n"
@knownLocations = TMsStrava::readKnownLocationsFromFile( $s{ 'fileKnownLocations' } );
foreach my $item ( @knownLocations ) {
  my @L = @{ $item };    # each line is an $arrayref
  $item = join " ", @L;
}

say '
<form action="knownLocations.pl?session=' . $s{ 'session' } . '" method="post">
<table border="1">
<tr><th>Locations<br/><small>example: 51.070298 13.760067 DD-Alaunpark</small></th></tr>
<tr><td>
<textarea name="knownLocations" cols="60" rows="20">
' . join( "\n", @knownLocations ) . '
</textarea>
</td></tr>
</table>
<input type="hidden" name="session" value="' . $s{ 'session' } . '"/>
<input type="submit" name="submit" value="Submit"/>
</form>
';

TMsStrava::htmlPrintFooter( $cgi );