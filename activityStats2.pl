#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# renders html for Activity Stats2
# calls activityStats2.py via Rest API (FastAPI)

# TODO

# IDEAS

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                  # say
use Data::Dumper;
use utf8;                   # this script is written in UTF-8
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard
use Encode qw(encode decode);

# use File::Path qw/remove_tree/;
use Time::Local;
use Storable;               # read and write variables to
use File::Basename;         # for basename, dirname, fileparse
use File::Copy;
use Cwd;                    # for my $dir = getcwd;

# Modules: Web
use CGI;
my $cgi = CGI->new;

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use TMsStrava qw( %o %s);
# at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Activity Statistics V2' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

# V1 via curl
# say
#     `curl -X POST "https://entorb.net/strava-be/activityStats2/" -H "Content-Type: application/json" -d '{"sessionId": "$s{'session'}"}'`;

# V2 via LWP
my $uri  = "https://entorb.net/strava-be/activityStats2/";
my $json = "{\"sessionId\": \"$s{'session'}\"}";
my $req  = HTTP::Request->new( 'POST', $uri );
$req->header( 'Content-Type' => 'application/json' );
$req->content($json);
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 }, );
# request debugging
# $ua->add_handler( "request_send",  sub { shift->dump; return } );
# $ua->add_handler( "response_done", sub { shift->dump; return } );
my $res = $ua->request($req);

if ( $res->code() == 200 ) {
  # parse html template
  my $fileIn = "activityStats2.html";
  open my $fhIn, '<:encoding(UTF-8)', $fileIn
      or die "ERROR: Can't read from file '$fileIn': $!";
  my $cont = do { local $/ = undef; <$fhIn> };
  close $fhIn;
  $cont =~ s/^.*<body>(.*)<\/body>.*/$1/s;
  $cont =~ s/SessionIdPlaceholder/$s{'session'}/s;
  say $cont;
} ## end if ( $res->code() == 200)
else {
  say "<p>Error in request</p>";
}
# say "</p>$s{'session'}</p>";

TMsStrava::htmlPrintFooter($cgi);
