#!/usr/bin/perl -w

# by Torben Menke https://entorb.net

# DESCRIPTION
# Import and creation of activities via copy & paste from Excel

# TODO

# IDEAS

# DONE

# Modules: My Default Set
use strict;
use warnings;
use 5.010;    # say
use Data::Dumper;
use utf8;     # this script is written in UTF-8
use Encode qw(encode decode);
binmode STDOUT, ':utf8';    # default encoding for linux print STDOUT

# Modules: Perl Standard
use Storable;               # read and write variables to filesystem

# use File::Basename;         # for basename, dirname, fileparse
# use File::Path qw(make_path);

# Modules: Web
use CGI;
my $cgi = CGI->new;

#use CGI ":all";
#use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Modules: My Strava Module Lib
use lib ('.');
use lib "C:\\Users\\menketrb\\Documents\\Hacken\\Perl\\Strava-Web";    # just for making Visual Studio Code happy
use lib "d:\\files\\Hacken\\Perl\\Strava-Web";
use TMsStrava qw( %o %s);                                              # at entorb.net some modules require use local::lib!!!

TMsStrava::htmlPrintHeader( $cgi, 'Import activities' );
TMsStrava::initSessionVariables( $cgi->param("session") );
TMsStrava::htmlPrintNavigation();

my $importtext = '';

if ( $cgi->param('importtext') or $cgi->param('submit') ) {
	$importtext = decode( 'UTF-8', $cgi->param('importtext') );
	$importtext =~ s/[\r\n ]+$//;                                        # remove whitespaces (excluding tab) from end of textfield
}

my $tableheader = '
<tr>
<th>Type<br/><small>Run/<br/>Ride/<br/>Swim</small></th>
<th>Date<br/><small>YYYY-MM-DD HH:MM:SS<br/>2019-05-14 20:45:00</small></th>
<th>Duration<br/><small>seconds<br/>3600</small></th>
<th>Distance*<br/><small>meter<br/>12000</small></th>
<th>Name<br/><small>Activity title<br/>&nbsp;</small></th>
<th>Description*<br/><small>Some description<br/>&nbsp;</small></th>
<th>Commute*<br/><small>1/0<br/>&nbsp;</small></th>
<th>OnTrainer*<br/><small>1/0<br/>&nbsp;</small></th>
<th>Elevation gain*<br/><small>meter<br/>123</small></th>
<th>Gear ID*<br/><small>&nbsp;<br/>g1195471</small></th>
</tr>
';

#
# Disclaimer
#
say "<p><i>The upload is currently limited to only 100 rows per run.</i></p>";

#
# INPUT MODE
#
# display input textarea only if not in preview or submit mode
if ( not $cgi->param('preview') and not $cgi->param('submit') ) {
	say '<h2>Input</h2>
<ul>
<li>Use <a href="/strava/download/StravaImportTemplate.xlsx" target="_blank">this template</a> to prepare a list of activities in Excel</li>
<li>Ensure to use the following date format \'YYYY-MM-DD HH:MM:SS\'</li>
<li>Copy and paste from Excel into the textbox below</li>
<li>Tipp: Test the import with one activity until everything works as expected, only than add more</li>
<li>Note: The Strava API allows only for <a href="https://developers.strava.com/docs/reference/#api-Activities-createActivity" target="_blank">very few parameters for activity creation</a>, so I can not add more</li>
<li>A list of already used gear_ids can be found below after caching your activities</li>
<li>Alternatively set a default gear prior to importing the data, and uses "0" as gear ID</li>
<li>Guide by Tony for bikes only: To find the gear ID, log into your Strava account. Navigate to Settings/My Gear and a list of your gear appears. Go into each bike that is listed in turn. At the top of the page the URL will appear as (eg) www.strava.com/bikes/6510003 . The 6510003 is the gear ID for that bike. Make a note of that number and prefix it with a lower case b and the result (eg: b6510003) is the value to input as Gear ID for that particular bike on the spreadsheet that you wish to load. If you don\'t put in a gear ID, the ride will be logged against your default bike.</li>
</ul>';

	say '<form action="activityExcelImport.pl?session=' . $s{'session'} . '" method="post">
<table border="1">
' . $tableheader . '
</table>
<small>* = optional, columns separated by tab, duration and distance without decimals, gear_id can be found in a table below <u>after</u> caching you activities first</small><br/>
<p>Example:<br/>
<code>Run[tab]2012-02-14 09:00:00[tab]1800[tab]5000[tab]Mit Hans im schoenen Skiurlaub[tab][tab]0[tab]0[tab]20[tab]g1195471[linebreak]</code></p>
<textarea name="importtext" cols="90" rows="20">' . $importtext . '</textarea>
<input type="hidden" name="session" value="' . $s{'session'} . '"/>
<br/>
<input type="submit" name="preview" value="Preview"/>
</form>
';

	my %gear;
	if ( -f $s{'pathToGearHashDump'} ) {
		%gear = %{ retrieve( $s{'pathToGearHashDump'} ) };    # retrieve data from file (as ref)
	}
	if (%gear) {                                            # gear hash is not empty
		say '<h3>List of gear used in cached activities</h3>
<table border="1">
<tr><th>Gear ID</th><th>Gear Name</th></tr>';
		foreach my $gear_id ( sort keys %gear ) {
			say "<tr><td>$gear_id</td><td>$gear{$gear_id}</td></tr>";
		}
		say '</table>';
	} else {
		say "<p>Cache your activities first to display a list of your gear_id (shoes/bikes) here.</p>";
	}

} ## end if ( not $cgi->param( ...))

#
# PREVIEW MODE
#
if ( $cgi->param('preview') ) {

	# display submit button only if in preview mode
	my @lines = split /\r?\n/, $importtext;
	say '
<h2>Preview</h2>
<table border="1">
' . $tableheader . '
<tbody align="center">';
	my $lineNo = 0;
	my $error  = '';

	foreach my $line (@lines) {
		$lineNo++;
		if ( $lineNo > 100 ) {
			$error = "Due to test phase, this feature is limited to only 100 rows at once. You entered " . ( $#lines + 1 ) . " rows.";
			last;
		}

		@_ = split "\t", $line;
		if ( $#_ != ( 10 - 1 ) ) {
			$error .= "<br/>10 columns expected, " . ( $#_ + 1 ) . " found";
		}
		my ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id ) = extractFromLine($line);
		$error .= check( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id );

		if ( $error ne '' ) {
			$error = "Error in line $lineNo:<br/>'$line'$error";
			last;
		} else {

			# say "$lineNo: $line<br>";
			say "<tr>
<td>$type</td>
<td>$date</td>
<td>$duration</td>
<td>$dist</td>
<td>$name</td>
<td>$desc</td>
<td>$commute</td>
<td>$trainer</td>
<td>$elev_gain</td>
<td>$gear_id</td>
</tr>
"
		} ## end else [ if ( $error ne '' ) ]
	} ## end foreach my $line ( @lines )
	say '
</tbody></table>';
	if ( $error ne '' ) {
		say "<p><font color=\"red\">$error</font></p>";
	}
	say '
<form action="activityExcelImport.pl?session=' . $s{'session'} . '" method="post">
<input type="hidden" name="session" value="' . $s{'session'} . '"/>
<input type="hidden" name="importtext" value="' . $importtext . '"/>
<br/>
<input type="submit" name="back" value="Back"/>
';
	if ( $error eq '' ) {
		say '<input type="submit" name="submit" value="Submit"/>';
	}
	say '</form>';
} ## end if ( $cgi->param( 'preview'...))

#
# SUBMIT MODE
#
if ( $cgi->param('submit') ) {
	say '<h2>Submit</h2>';
	my @lines = split /\r?\n/, $importtext;
	say '<table border="1">
' . $tableheader . '
<tbody align="center">';
	foreach my $line (@lines) {
		my ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id ) = extractFromLine($line);
		$date =~ s/^(\d{4}\-\d{2}\-\d{2}) (\d{2}:\d{2}:\d{2})$/$1T$2Z/;    #  "2018-02-20T10:02:13Z"
		 # if time is 00:00:00 -> 00:00:01 to ensure the correct day is used by Strava
		$date =~ s/T00:00:00Z/T00:00:01Z/;
		foreach my $s ( $name, $desc ) {
			$s =~ s/\s+/%20/g;                                               # replace spaces by %20
			 # UTF -> HTML, not working as in "schön"
			 # from https://stackoverflow.com/questions/12790643/convert-utf-8-into-html
			 # $name = join q(), map { ord > 127 ? "&#" . ord . ";" : $_ } split //, $name;
			 #  $s =~ s/([^[\x20-\x7F])/"&#" . ord($1) . ";"/eg;;
		} ## end foreach my $s ( $name, $desc)

		# say "'$_'" foreach ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain );
		my $param = "name=$name&type=$type&start_date_local=$date&elapsed_time=$duration&description=$desc&distance=$dist&trainer=$trainer&commute=$commute&elev_gain=$elev_gain&gear_id=$gear_id";
		if ($type eq 'Swim') {
			$param = "name=$name&type=$type&start_date_local=$date&elapsed_time=$duration&description=$desc&distance=$dist";
		}

		# say "<p><code>debug for Dave 1:<br/>param= '$param'</code></p>";

		# say "<p>param = $param</p>";
		# say "<p>token = $s{ 'token' }</p>";
		my $url = $o{'urlStravaAPI'} . "/activities?$param";

		# say "<p>url: $url</p>";
		my ( $htmlcode, $cont ) = TMsStrava::PostPutJsonToURL( 'POST', $url, $s{'token'}, 1 );    # = silent: (1-> do not die on http error)
		if ( $htmlcode != 201 ) {
			say "<p><font color=\"red\">ERROR $htmlcode at line<br/>'$line'<br/>url: $url<br/>return: $cont</font></p>";
		} else {

			# say "Strava answers:<br/>$htmlcode: $cont";
			my %h = TMsStrava::convertJSONcont2Hash($cont);

			# say "<p><code>debug for Dave 3 - hash:<br/>";
			# say Dumper %h;
			# say "</code></p>";
			say '<tr>
      <td>' . $h{"type"} . '</td>
      <td>' . $h{"start_date_local"} . '</td>
      <td>' . $h{"moving_time"} . '</td>
      <td>' . $h{"distance"} . '</td>
      <td>' . TMsStrava::activityUrl( $h{"id"}, $h{"name"} ) . '</td>
      <td>' . $h{"description"} . '</td>
      <td>' . $h{"commute"} . '</td>
      <td>' . $h{"trainer"} . '</td>
      <td>' . $h{"total_elevation_gain"} . '</td>
      <td>' . $h{"gear_id"} . '</td>
      </tr>';

		} ## end else [ if ( $htmlcode != 201 )]
	} ## end foreach my $line ( @lines )
	say '</tbody></table>';
} ## end if ( $cgi->param( 'submit'...))
TMsStrava::htmlPrintFooter($cgi);


sub check {
	my ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id ) = @_;
	my $error = '';
	if ( not grep { $type eq $_ } qw (Run Ride Swim) ) {
		$error .= "<br/>Type '$type' must be Run, Ride or Swim.";
	}
	if ( not $date =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/ ) {    # YYYY-MM-DD HH:MM:SS
		$error .= "<br/>Date '$date' must be formatted YYYY-MM-DD HH:MM:SS.";
	} else {
		my ( $y, $m, $d, $h, $mi, $s ) = ( $1, $2, $3, $4, $5, $6 );
		if ( $m > 12 ) {
			$error .= "<br/>Month '$m' must be <= 12";
		}
	} ## end else [ if ( not $date =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/)]
	if ( not $duration =~ m/^\d+$/ ) {
		$error .= "<br/>Duration '$duration' can only contain numbers (no ',' or '.').";
	}
	if ( not $dist =~ m/^\d*$/ ) {
		$error .= "<br/>Distance '$dist' can only contain numbers (no ',' or '.').";
	}
	if ( not $elev_gain =~ m/^\d*$/ ) {
		$error .= "<br/>Elevation gain '$elev_gain' can only contain numbers (no ',' or '.').";
	}
	if ( not $name =~ m/^[ a-zA-Z0-9:;,\.!\?\(\)\[\]<>\{\}]+$/ ) {
		$error .= "<br/>Name '$name' shall only contain 'a-z A-Z 0-9:;,.!?()[]<>{}'.";
	}
	if ( not $desc =~ m/^[ a-zA-Z0-9:;,\.!\?\(\)\[\]<>\{\}]*$/ ) {
		$error .= "<br/>Description '$desc' shall only contain 'a-z A-Z 0-9:;,.!?()[]<>{}'.";
	}
	if ( not grep { $commute eq $_ } ( '1', '0', '' ) ) {
		$error .= "<br/>Commute '$commute' shall be 1 or 0.";
	}
	if ( not grep { $trainer eq $_ } ( '1', '0', '' ) ) {
		$error .= "<br/>Trainer '$trainer' shall be 1 or 0.";
	}
	if ( not $gear_id =~ m/^[a-zA-Z0-9]*$/ ) {
		$error .= "<br/>Gear ID '$gear_id' shall only contain 'a-z A-Z 0-9";
	}
	return $error;
} ## end sub check


sub extractFromLine {
	my ($line) = @_;
	chomp($line);    # remove \n
	@_ = split "\t", $line;
	@_ = map { s/(^\s*|\s*$)//g; $_; } @_;    # trim spaces from start and end
	my ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id ) = @_;
	$commute = '0' if $commute eq '';
	$trainer = '0' if $trainer eq '';
	$desc    = ''  if $desc eq '0';
	$gear_id = ''  if $gear_id eq '0';
	return ( $type, $date, $duration, $dist, $name, $desc, $commute, $trainer, $elev_gain, $gear_id );
} ## end sub extractFromLine
