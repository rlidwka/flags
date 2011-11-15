#!/usr/bin/perl

use strict;
use utf8;
use DBI;
use Common;
use CGI qw/-utf8 :standard/;
use Data::Dumper;
use HTML::Entities qw(decode_entities);
use URI::Escape;

web_init();

sub get_sql_order
{
	my $sortorder = shift;
	my %sorts = (
		"ip" => "ORDER BY `from` ASC, `anstime` DESC",
		"ipinv" => "ORDER BY `from` DESC, `anstime` DESC",
		"flag" => "ORDER BY `flag` ASC, `anstime` DESC",
		"flaginv" => "ORDER BY `flag` DESC, `anstime` DESC",
		"ans" => "ORDER BY `answer` ASC, `anstime` DESC",
		"ansinv" => "ORDER BY `answer` DESC, `anstime` DESC",
		"add" => "ORDER BY `addtime` ASC, `anstime` ASC",
		"addinv" => "ORDER BY `addtime` DESC, `anstime` DESC",
		"last" => "ORDER BY `anstime` ASC",
		"lastinv" => "ORDER BY `anstime` DESC",
	);
	return $sorts{$sortorder};
}

sub makelink
{
	my ($key, $value) = @_;
	my $url = self_url();
	if ($url =~ /[\?&;]$key=/) {
		$url =~ s/([\?&;])$key=[^&;]+/\1$key=$value/;
	} else {
		$url .= (index($url, '?')==-1?'?'.$key.'='.$value:';'.$key.'='.$value);
	}
	return $url;
}

sub makeorderlink
{
	my ($sortorder, $url, $desc, $inv) = @_;
	if ($sortorder eq $url.'inv') {
		return '<a style="color:#005500;" href="'.makelink('sort', $url).'">'.$desc.($inv?'↓':'↑').'</a>';
	} elsif ($sortorder eq $url) {
		return '<a style="color:#005500;" href="'.makelink('sort', $url.'inv').'">'.$desc.($inv?'↑':'↓').'</a>';
	} else {
		return '<a href="'.makelink('sort', $url).'">'.$desc.'</a>';
	}
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

my $order = 'lastinv';
if (param('sort')) {
	$order = param('sort');
}
my $ordersql = get_sql_order($order);

print '<div align="center" class="result">';
print '<table width="60%"><tr>';
print '<th>'.makeorderlink($order, 'ip', 'IP').'</th>';
print '<th>'.makeorderlink($order, 'flag', 'Flag').'</th>';
print '<th>'.makeorderlink($order, 'ans', 'Answer').'</th>';
print '<th>'.makeorderlink($order, 'add', 'Add time').'</th>';
print '<th>'.makeorderlink($order, 'last', 'Last answer').'</th>';
print '</tr>';

my @flags;
if (param('ip')) {
	@flags = @{$dbh->selectall_arrayref("SELECT `from`,`flag`,`answer`,`resubmit`,`isok`,addtime,anstime FROM `flags` WHERE `from`=? $ordersql", undef, param('ip'))};
} else {
	@flags = @{$dbh->selectall_arrayref("SELECT `from`,`flag`,`answer`,`resubmit`,`isok`,addtime,anstime FROM `flags` $ordersql")};
}

foreach (@flags) {
	if ($_->[3]) {
		print '<tr>';
	} elsif ($_->[4]) {
		print '<tr class="ok">';
	} else {
		print '<tr class="wrong">';
	}
	print '<td>'.encode_entities($_->[0]).'</td>';
	print '<td>'.encode_entities($_->[1]).'</td>';
	print '<td>'.encode_entities($_->[2]).'</td>';
	print '<td>'.encode_entities($_->[5]).'</td>';
	print '<td>'.encode_entities($_->[6]).'</td>';
	print '</tr>';
}

print '</table></div>';

print end_html();

$dbh->disconnect();

