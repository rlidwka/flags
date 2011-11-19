#!/usr/bin/perl

use strict;
use utf8;
use DBI;
use CGI qw/-utf8 :standard/;
use Data::Dumper;
use Common;
use HTML::Entities qw(decode_entities);

web_init();

our $dbh = connectdb();

print header(
	-type => 'text/html',
	-charset => 'UTF-8'
);

print start_html({
	-title => 'Flag submitter',
	-head => [
		Link({-rel => "stylesheet", -type => "text/css", -href => "style.css"}),
	],
});

my @flags = ();
if (param('flags')) {
	@flags = map {
		[addflag($dbh, $_, "http/".remote_host())];
	} strtoflags(param('flags'));
}

print '<body>';
if (param('flags')) {
	if (@flags) {
		print '<div class="result" align="center"><table width="60%" class="table">';
		print '<th>Flag</th><th>Result</th>';
		print join '', map {
			my $r = '<tr class="'.$_->[2].'">';
			$r .= '<td>'.encode_entities($_->[0]).'</td>';
			$r .= '<td>'.$_->[1].'</td>';
			$r .= '</tr>';
			$r;
		} @flags;
		print '</table></div>';
	} else {
		print '<div class="result" align="center">No flags detected here</div>';
	}
}
print '<div class="submit"><form method="POST" action="submit.pl">';
print '<div><textarea name="flags" cols="80" rows="30"></textarea></div>';
print '<div><input type="submit" value="submit"/></div>';
print '</form></div>';
print '</body>';

print end_html();

$dbh->disconnect();

