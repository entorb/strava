#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# use gnuplot to display usage stats for this app

# TODO

# IDEAS

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;                      # say
use Data::Dumper;
use utf8;                       # this script is written in UTF-8
binmode STDOUT, ':utf8';        # default encoding for linux print STDOUT
use autodie qw (open close);    # Replace functions with ones that succeed or die: e.g. close

# pp -u -M Excel::Writer::XLSX -o script.exe script.pl & copy script.exe c:\tmp

# Modules: Perl Standard
# use Encode qw(encode decode);
# use open ":encoding(UFT-8)";    # for all files

# Modules: File Access
use File::Basename;    # for basename, dirname, fileparse
use File::Path qw(make_path remove_tree);

# Modules: CPAN
# use LWP::UserAgent; # http requests
# use Excel::Writer::XLSX;
# perl -MCPAN -e "install Excel::Writer::XLSX"

use CGI;
my $cgi = new CGI;

#use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

print $cgi->header(
    -type    => 'text/html',
    -charset => 'utf-8'
);
print $cgi->start_html(
    -title => 'Torben\'s Strava App Stats',
    -meta  => { 'author' => 'Torben Menke' },
    -style => { -src     => '/style.css' }
);

my %o;
$o{'dataFolderBase'} = '/var/www/virtual/entorb/data-web-pages/strava';
my $fileIn = $o{'dataFolderBase'} . '/login.log';

open my $fhIn, '<', $fileIn
    or die "ERROR: Can't read from file '$fileIn': $!";

my %h;    # temp

# remove multiple logins per day via reduction to
# yy-mm-dd<TAB>userid

foreach my $line (<$fhIn>) {
    chomp $line;                   # remove \n;
    my ( $date, $userid, $username, $scope ) = split /\t/, $line;
    $userid += 0;                  # convert to number
    next if $userid == 7656541;    # that is me
    $date =~ m/^(\d+)\.(\d+)\.(\d+) .*/;
    $date = $_ = sprintf "%02d-%02d-%02d", $3 - 2000, $2, $1;
    $_    = "$date\t$userid";
    $h{$_}++;
} ## end foreach my $line (<$fhIn>)
close $fhIn;

my @visitingDays = sort keys %h;    # yy-mm-dd<TAB>userid
undef %h;

say "<h1>Usage Stats</h1>";

# fill hashes
my %userVisitCount = ();
my %visitorsPerDay;
my %usersPerMonth    = ();
my %newUsersPerMonth = ();
my @knownUsers;

foreach my $line (@visitingDays) {
    my ( $day, $userid ) = split "\t", $line;
    $userid += 0;    # convert to number
    $userVisitCount{$userid}++;
    $visitorsPerDay{$day}++;
    my $month = $day;
    $month =~ s/\-\d+$//s;
    $usersPerMonth{$month}++;
    if ( not grep { $userid eq $_ } @knownUsers ) {
        push @knownUsers, $userid;
        $newUsersPerMonth{$month}++;
    } else {
        $newUsersPerMonth{$month} += 0;    # initialize if not present
    }

} ## end foreach my $line (@visitingDays)

# unique users
@_ = keys %userVisitCount;
my $anzUsers             = ( $#_ + 1 );
my $anzLogins            = 0;
my $anzRepeatingVisitors = 0;
foreach my $user ( keys %userVisitCount ) {
    $anzLogins += $userVisitCount{$user};
    $anzRepeatingVisitors++ if ( $userVisitCount{$user} ) > 1;
}
say "<p>";
say
    "$anzLogins logins by $anzUsers unique and $anzRepeatingVisitors returning users.";
say "</p>";

# # due to privacy reasons: not printed on web!
# %h = %userVisitCount;
# say "<h2>recurring user ranking</h2>";
# say "<table border=1>";
# say "<tr><th>user</th><th>total</th></tr>";
# foreach my $k ( sort { $h{ $b } <=> $h{ $a } } keys %h ) {
#   last if $h{ $k } == 1;
#   say "<tr><td>$k</td><td>$h{$k}</td></tr>"; # https://www.strava.com/athletes/$k
# }
# say "</table>";

my $fileOut = "stats.dat";
open my $fhOut, '>:encoding(UTF-8)', $fileOut
    or die "ERROR: Can't write to file '$fileOut': $!";
say {$fhOut} "# month_dec\tmonth\ttotal\tnew\treturning";

%h = %usersPerMonth;
say "<h2>users per month</h2>";
say "<table border=1>";
say
    "<tr><th>month</th><th>total</th><th>new</th><th>returning</th><th>% returning</th></tr>";

# foreach my $mon ( reverse sort keys( %h ) ) {
my @dataforfile;
foreach my $mon ( reverse sort keys(%h) ) {

    # say "$mon\t$usersPerMonth{$mon}";
    say
        "<tr><td>$mon</td><td>$h{$mon}</td><td>$newUsersPerMonth{$mon}</td><td>"
        . ( $h{$mon} - $newUsersPerMonth{$mon} )
        . "</td><td>"
        . sprintf "%d</td></tr>",
        100 * ( $h{$mon} - $newUsersPerMonth{$mon} ) / $h{$mon};

    # 18-10 -> 2018 + 9/12
    $_ = $mon;
    @_ = split "-", $mon;
    my $month_dec = sprintf "%.02f", 2000 + $_[ 0 ] + ( $_[ 1 ] - 1 ) / 12;

    # unshift because html table is desc
    unshift @dataforfile,
        "$month_dec\t$mon\t$h{$mon}\t$newUsersPerMonth{$mon}\t"
        . ( $h{$mon} - $newUsersPerMonth{$mon} );
} ## end foreach my $mon ( reverse sort...)
say "</table>";

foreach my $line (@dataforfile) {
    say {$fhOut} $line;
}
close $fhOut;

# run gnuplot, but only if app-stats.png is older than 15 min
$_ = ( stat('stats.png') )[ 9 ];    # mtime as timestamp
if ( time - $_ > 900 ) {
    `gnuplot gnuplot/app-stats.gp`;
}

say
    "<p><img src=\"stats.png\" alt=\"stats.png\" width=\"1200\" height=\"600\" /></p>";

# %h = %visitorsPerDay;
# say "<h2>users per day</h2>";
# say "<table border=1>";
# say "<tr><th>day</th><th>total</th></tr>";
# foreach my $k ( reverse sort keys(%h) ) {
#     ## say "$k\t$usersPerMonth{$k}";
#     say "<tr><td>$k</td><td>$h{$k}</td></tr>";
# }
# say "</table>";

unlink $fileOut;
print $cgi->end_html;
