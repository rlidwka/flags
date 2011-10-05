#!/usr/bin/perl
package Common;
use Exporter;
use warnings;
use strict;
use DBI;
use HTML::Entities qw(decode_entities);
use CGI qw/-utf8 :standard/;

our @ISA = qw(Exporter);
our @EXPORT = qw(connectdb strtoflags addflag encode_entities allowed_ip raise_error);

sub allowed_ip
{
	my $ip = shift;
	return $ip !~ /^10\./;
	return scalar grep {
		$_ eq $ip;
	} split ' ', '::1 127.0.0.1 178.46.215.231';
}

sub raise_error
{
	print header(
		-type => 'text/html',
		-charset => 'UTF-8'
	);

	print '<b>Parse Error</b>: syntax error, unexpected $end in </b>c:\www\mysite\modules\user.php</b> on line <b>4</b>';
}

sub encode_entities
{
	return HTML::Entities::encode_entities($_[0], "<>&\"'");
}

sub connectdb
{
	my $dbh = DBI->connect('DBI:mysql:flags', 'flags', 'HSSwtfRRVVFDtErU', { mysql_enable_utf8 => 1 }) 
		or die "Could not connect to database: $DBI::errstr";
	$dbh->do("set character set utf8");
	$dbh->do("set names utf8");
	return $dbh;
}

sub strtoflags
{
	$_ = shift;
#	return m/(\d+)/g;
#	return m/[a-zA-Z0-9]{30}==/g;
#	return m/[a-f0-9]{32}/ig;
	return m/[a-zA-Z0-9]{32,}/g;
}

sub addflag
{
	my $dbh = shift;
	$_ = shift;
	my $from = shift;
	my $ref = $dbh->selectrow_arrayref('SELECT `from`,answer FROM flags WHERE flag=?', undef, $_);
	if (ref $ref) {
		my ($from, $ans) = map {
			encode_entities $_;
		} @$ref;
		if (!$ans) {
			return $_, "already submitted by <b>$from</b> (not checked yet)", 'wrong';
		} else {
			return $_, "already submitted by <b>$from</b> (result: <b>$ans</b>)", 'wrong';
		}
	} else {
		$dbh->do('INSERT INTO flags (flag,`from`,resubmit,anstime) VALUES (?, ?, ?, NOW())', undef, $_, $from, 1);
		return $_, "ok", 'ok';
	}
}

1;
