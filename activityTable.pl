#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# display statistics for cached activities

# TODO
# For the yearly averages 0 values need to be used to fill the gaps
#  this is wrong for pace and other averages!!!
# For the av_all this is wrong!!!

# IDEAS
# * mark record per date bold
# * add record activity value

# DONE
# * add quarter

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

TMsStrava::htmlPrintHeader( $cgi, 'Activity table' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

print '

    <script src="./activity-tabulator.js"></script>
    <script src="/COVID-19-coronavirus/js/jquery-3.5.0.min.js"></script>
    <!-- Polyfiles for IE, suggested by Tabulator : http://tabulator.info/docs/4.6/browsers#ie -->
    <script src="/COVID-19-coronavirus/js/tabulator-polyfill.min.js"></script>
    <script src="/COVID-19-coronavirus/js/tabulator-fetch.umd.js"></script>
    <!-- Tabulator -->
    <link href="/COVID-19-coronavirus/js/tabulator.min.css" rel="stylesheet">
    <script src="/COVID-19-coronavirus/js/tabulator-4.6.min.js"></script>
    <div id="table-activity-list"></div>
    <!--
    Start JavaScript
  -->
    <script>
        // variables
        const promises = []; // array of promises for async fetching

        // ASync JQuery fetching
        function fetch_table_data() {
            table.setData("https://entorb.net/strava/'
    . $s{'pathToActivityListJsonDump'} . '", {}, "get")
        }

        // define and populate table
        var table = defineTable();
        promises.push(fetch_table_data());
        table.setSort("x_date", "desc");

    </script>
';

TMsStrava::htmlPrintFooter($cgi);
