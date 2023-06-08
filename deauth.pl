#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# deauthorize via Strava API

# TODO

# IDEAS

# DONE
# Move Token from Parameter to Contents (Header)

# Modules: My Default Set
use strict;
use warnings;
use 5.010;    # say
use Data::Dumper;
use utf8;     # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard
use File::Path qw/remove_tree/;

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

TMsStrava::htmlPrintHeader( $cgi, 'Deauthorization');

# Check for present and valid parameter session
TMsStrava::initSessionVariables( $cgi->param( "session" ) );

# my ($stravaUserID2, $stravaUsername2) = TMsStrava::whoAmI($token);
# print Dumper ($stravaUserID2, $stravaUsername2) ;

remove_tree( $s{ 'tmpDataFolder' } )     if ( -d $s{ 'tmpDataFolder' } );
remove_tree( $s{ 'tmpDownloadFolder' } ) if ( -d $s{ 'tmpDownloadFolder' } );

TMsStrava::deauthorize( $s{ 'token' }, 0 );    # 2nd paramter-> silent or stop on error
# TMsStrava::htmlPrintNavigation();

say "<p>Deauthorization and deletion of temporary files successful. I hope this app helped you $s{'stravaUsername'}</p>";
say '<p><a href="index.html">Back to start</a></p>';

TMsStrava::htmlPrintFooter( $cgi );
