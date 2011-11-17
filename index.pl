#!/usr/bin/perl

use strict;
use utf8;
use Common;
use DBI;
use CGI qw/-utf8 :standard/;
use Data::Dumper;
use HTML::Entities qw(decode_entities);
use URI::Escape;

web_init();

our $dbh = connectdb();

print header(
	-type => 'text/html',
	-charset => 'UTF-8'
);

my $start = start_html({
	-title => 'Flag submitter',
	-head => [
		Link({-rel => "stylesheet", -type => "text/css", -href => "style.css"}),
	],
	-script => {-src=>'scripts.js'},
});
# patch for html5
$start =~ s{<!DOCTYPE.*?>}{<!DOCTYPE html>}s;
print $start;

print '<div><canvas id="graph" width=100 height=50>[ вам определённо пора обновить браузер :) ]</canvas></div>';
print '<div><a href="submit.pl">Добавить флаги...</a></div><br>';

sub printcell 
{
	my $x = shift;
	my $diff = shift;
	if ($diff) {
		return sprintf "<td>%d <font color=\"green\">(+%d)</font></td>", $x, $diff;
	} else {
		return sprintf "<td>%d</td>", $x;
	}
}

sub showstat {
#	my $ishour = shift;
	print '<div align="center" class="result"><table width="60%"><tr><th width="20%">IP</th><th width="20%">Processing</th><th width="20%">Accepted</th><th width="20%">Rejected</th><th width="20%">Total</th></tr>';
	my %flags_h = %{$dbh->selectall_hashref("SELECT `from`, COUNT(*) as `total`, SUM(`resubmit`) as `resubmit`, SUM(`isok`) as `accepted` FROM `flags` WHERE `anstime` > DATE_SUB(NOW(), INTERVAL 1 HOUR) GROUP BY `from`", 'from')};
	my %flags = %{$dbh->selectall_hashref("SELECT `from`, COUNT(*) as `total`, SUM(`resubmit`) as `resubmit`, SUM(`isok`) as `accepted` FROM `flags` GROUP BY `from`", 'from')};
	my $str = '';
	
	my @res = (0, 0, 0, 0);
	my @resh = (0, 0, 0, 0);
	foreach (sort {$a<=>$b} keys %flags) {
		my $h = $flags_h{$_};
		my $f = $flags{$_};
		my ($t, $d);
		$str .= '<tr>';
		$str .= '<td><a href="list.pl?ip='.uri_escape($f->{from}).'">'.encode_entities($f->{from}).'</a></td>';
		$res[0] += $t = int($f->{resubmit});
		$resh[0] += $d = ref $h ? int($h->{resubmit}) : 0;
		$str .= printcell($t, $d);
		$res[1] += $t = int($f->{accepted});
		$resh[1] += $d = ref $h ? int($h->{accepted}) : 0;
		$str .= printcell($t, $d);
		$res[2] += $t = int($f->{total}) - int($f->{accepted}) - int($f->{resubmit});
		$resh[2] += $d = ref $h ? int($h->{total}) - int($h->{accepted}) - int($h->{resubmit}) : 0;
		$str .= printcell($t, $d);
		$res[3] += $t = int($f->{total});
		$resh[3] += $d = ref $h ? int($h->{total}) : 0;
		$str .= printcell($t, $d);
		$str .= '</tr>';
	}
	print '<tr>';
	print '<td><a href="list.pl">-- All flags --</a></td>';
	print printcell($res[$_], $resh[$_]) for (0..3);
	print '</tr>';
	print '<tr><td colspan=5></td></tr>';

	print $str;
	print '</table></div>';
}

sub showans {
	print '<div align="center" class="result"><table width="60%"><tr><th width="20%">Answer</th><th width="20%">First time</th><th width="20%">Count</th><th width="20%">Action</th></tr>';
	my @ans = @{$dbh->selectall_arrayref("SELECT answer,action,count,first from answers ORDER BY answer")};

	foreach (@ans) {
		print '<tr>';
		print '<td>'.$_->[0].'</td>';
		print '<td>'.$_->[3].'</td>';
		print '<td>'.$_->[2].'</td>';
		print '<td>'.$_->[1].'</td>';
		print '</tr>';
	}
	print '</table></div>';
}

#print "<h3>Last hour</h3>";
#showstat(1);
#print "<h3>All time</h3>";
showstat();
print '<hr>';
print "<h4>Ответы системы (для дебага)</h4>";
showans();

my @graph = @{$dbh->selectall_arrayref("SELECT time_min,accepted,rejected from graph WHERE time_min > ?", undef, time()/60-60*24)};
print '<script language="javascript">';
print 'var data = [';
print join("\n", map {
	sprintf('["%d","%d","%d"],', @$_);
} @graph);
print '];';
print "draw_data(data, ".int(time()/60).");";
print '</script>';

print end_html();

$dbh->disconnect();

