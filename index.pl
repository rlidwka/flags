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

sub printcell 
{
	my $x = shift;
	my $diff = shift;
	if ($diff) {
		printf "<td>%d <font color=\"green\">(+%d)</font></td>", $x, $diff;
	} else {
		printf "<td>%d</td>", $x;
	}
}

sub showstat {
#	my $ishour = shift;
	print '<div align="center" class="result"><table width="60%"><tr><th width="20%">IP</th><th width="20%">Processing</th><th width="20%">Accepted</th><th width="20%">Rejected</th><th width="20%">Total</th></tr>';
	my %flags_h = %{$dbh->selectall_hashref("SELECT `from`, COUNT(*) as `total`, SUM(`resubmit`) as `resubmit`, SUM(`isok`) as `accepted` FROM `flags` WHERE `anstime` > DATE_SUB(NOW(), INTERVAL 1 HOUR) GROUP BY `from`", 'from')};
	my %flags = %{$dbh->selectall_hashref("SELECT `from`, COUNT(*) as `total`, SUM(`resubmit`) as `resubmit`, SUM(`isok`) as `accepted` FROM `flags` GROUP BY `from`", 'from')};
	
	my @res = (0, 0, 0, 0);
	my @resh = (0, 0, 0, 0);
	foreach (sort {$a<=>$b} keys %flags) {
		my $h = $flags_h{$_};
		my $f = $flags{$_};
		my ($t, $d);
		print '<tr>';
		print '<td><a href="list.pl?ip='.uri_escape($f->{from}).'">'.encode_entities($f->{from}).'</a></td>';
		$res[0] += $t = int($f->{resubmit});
		$resh[0] += $d = ref $h ? int($h->{resubmit}) : 0;
		printcell($t, $d);
		$res[1] += $t = int($f->{accepted});
		$resh[1] += $d = ref $h ? int($h->{accepted}) : 0;
		printcell($t, $d);
		$res[2] += $t = int($f->{total}) - int($f->{accepted}) - int($f->{resubmit});
		$resh[2] += $d = ref $h ? int($h->{total}) - int($h->{accepted}) - int($h->{resubmit}) : 0;
		printcell($t, $d);
		$res[3] += $t = int($f->{total});
		$resh[3] += $d = ref $h ? int($h->{total}) : 0;
		printcell($t, $d);
		print '</tr>';
	}
	print '<tr>';
	print '<td><a href="list.pl">All flags</a></td>';
	printcell($res[$_], $resh[$_]) for (0..3);
	print '</tr>';

	print '</table></div>';
}

#print "<h3>Last hour</h3>";
#showstat(1);
#print "<h3>All time</h3>";
showstat(0);

print end_html();

$dbh->disconnect();

