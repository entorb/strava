#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# displays tabulator table of cached activities

# TODO

# DONE
# * use html as template
# * use tabulator JS lib

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Web
use CGI;
my $cgi = CGI->new;

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use TMsStrava qw( %o %s)
    ;    # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Activity Table' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

my $fileIn = "activityTable.html";
open my $fhIn, '<:encoding(UTF-8)', $fileIn
    or die "ERROR: Can't read from file '$fileIn': $!";
my $cont = do { local $/ = undef; <$fhIn> };
close $fhIn;
$cont =~ s/^.*<body>(.*)<\/body>.*/$1/s;
$cont =~ s/SessionIDPlaceholder/$s{'session'}/s;

say $cont;

TMsStrava::htmlPrintFooter($cgi);
