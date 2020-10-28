#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION

# TODO

# IDEAS

# DONE
# - after successful modification, if present all jsons are deleted

# Modules: My Default Set
use strict;
use warnings;
use 5.010;    # say
use Data::Dumper;
use utf8;     # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard

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

TMsStrava::htmlPrintHeader( $cgi, 'Clear Cache');
TMsStrava::initSessionVariables( $cgi->param( "session" ) );
TMsStrava::clearCache();
TMsStrava::htmlPrintNavigation();

TMsStrava::htmlPrintFooter( $cgi );