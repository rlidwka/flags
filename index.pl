#!/usr/bin/perl

use strict;
use utf8;
use Common;
use DBI;
use CGI qw/-utf8 :standard/;
use Data::Dumper;
use HTML::Entities qw(decode_entities);
use URI::Escape;

binmode(STDOUT, ":utf8");

if (!allowed_ip(remote_host())) {
	raise_error();
	exit 0;
}

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

print '<div><a href="submit.pl">Добавить флаги...</a></div><br>';

sub showstat {
	my $ishour = shift;
	print '<div align="center" class="result"><table width="60%"><tr><th width="20%">IP</th><th width="20%">Processing</th><th width="20%">Accepted</th><th width="20%">Rejected</th><th width="20%">Total</th></tr>';
	my @flags;
	if ($ishour) {
		@flags = @{$dbh->selectall_arrayref("SELECT `from`, COUNT( * ) , SUM( `resubmit` ) , SUM( `isok` ) FROM `flags` WHERE `anstime` > DATE_SUB(NOW(), INTERVAL 1 HOUR) GROUP BY `from`")};
	} else {
		@flags = @{$dbh->selectall_arrayref("SELECT `from`, COUNT( * ) , SUM( `resubmit` ) , SUM( `isok` ) FROM `flags` GROUP BY `from`")};
	}
	
	my @res = (0, 0, 0, 0);
	foreach (@flags) {
		print '<tr>';
		print '<td><a href="list.pl?ip='.uri_escape($_->[0]).'">'.encode_entities($_->[0]).'</a></td>';
		$res[0] += $_->[2];
		print '<td>'.int($_->[2]).'</td>';
		$res[1] += $_->[3];
		print '<td>'.int($_->[3]).'</td>';
		$res[2] += $_->[1]-$_->[2]-$_->[3];
		print '<td>'.int($_->[1]-$_->[2]-$_->[3]).'</td>';
		$res[3] += $_->[1];
		print '<td>'.int($_->[1]).'</td>';
		print '</tr>';
	}
	print '<tr>';
	print '<td><a href="list.pl">All flags</a></td>';
	print '<td>'.int($res[0]).'</td>';
	print '<td>'.int($res[1]).'</td>';
	print '<td>'.int($res[2]).'</td>';
	print '<td>'.int($res[3]).'</td>';
	print '</tr>';

	print '</table></div>';
}

print "<h3>Last hour</h3>";
showstat(1);
print "<h3>All time</h3>";
showstat(0);

print end_html();

$dbh->disconnect();

