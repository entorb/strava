#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Download of cached activities in Excel format

# TODO

# IDEAS

# DONE
# Zipping source jsons

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
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
use lib ('.');
use lib ('/var/www/virtual/entorb/perl5/lib/perl5');
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web"
    ;    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s)
    ;    # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Excel export of activities' );
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

my $pathToExcel = "$s{'tmpDownloadFolder'}/ActivityList.xlsx";

# Generate Excel only if not already done
unless ( -f $pathToExcel ) {
  TMsStrava::convertActivityHashToExcel( 'ActivityList.xlsx',
    @allActivityHashes );
}

my $pathToZipRaw = "$s{'tmpDownloadFolder'}/ActivityListRaw.zip";

# zip source jsons if not already done
unless ( -f $pathToZipRaw ) {
  my $dir = dirname($pathToZipRaw);
  make_path $dir unless -d $dir;
  undef $dir;
  my @L = <$s{'tmpDataFolder'}/activityList/*.json>;
  TMsStrava::zipFiles( $pathToZipRaw, @L );
} ## end unless ( -f $pathToZipRaw )

my $pathToZip = "$s{'tmpDownloadFolder'}/ActivityList.zip";

# zip joined json if not already done
unless ( -f $pathToZip ) {
  my $dir = dirname($pathToZip);
  make_path $dir unless -d $dir;
  undef $dir;
  TMsStrava::zipFiles( $pathToZip, $s{'pathToActivityListJsonDump'} );
} ## end unless ( -f $pathToZip )

say "Downloads:
<ul>
<li><a href=\"$pathToExcel\">your data as Excel report</a> (fields of prefix 'x_' are extensions by this app and not present in the source .json)
<li><a href=\"download/ActivityListAnalysis.xlsx\">my Excel statistics template</a> (use to paste the values of your data from above generated Excel report)</li>
<li><a href=\"$pathToZip\">your data as zipped .json file (including calculated fields)</a></li>
<li><a href=\"$pathToZipRaw\">your raw data as zipped .json files (unmodified files retrieved from Strava)</a></li>
</ul>
";

TMsStrava::htmlPrintFooter($cgi);
