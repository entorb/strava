#!/usr/bin/perl -w
package TMsStravaSecret;

# by Torben Menke https://entorb.net

# DESCRIPTION
# stores my apps credentials

use Exporter qw( import );
our @EXPORT = qw( %secret );

our %secret;
$secret{'clientId'} = 12345;
$secret{'secret'}   = 'ObtainFromStrava'; # via https://www.strava.com/settings/api
$secret{'my-email'} = 'this-is-not-my-mail@entorb.net';

1;    # Module needs to return 1
