#!/usr/bin/perl
package Common;
use Exporter;
use warnings;
use strict;
use DBI;
use Data::Dumper;
use HTML::Entities qw(decode_entities);
use CGI qw/-utf8 :standard/;

our @ISA = qw(Exporter);
our @EXPORT = qw(connectdb strtoflags addflag encode_entities allowed_ip raise_error config web_init);

my $config = {};
open F, "Config.pl";
$config = eval(join "",<F>);
close F;

sub web_init
{
	binmode(STDOUT, ":utf8");

	if (!allowed_ip(remote_addr())) {
		raise_error();
		exit 0;
	}
}

sub see_config
{
	my $_config = shift;
	my $arg = shift;
	return undef unless (ref $_config);
	return $_config->{$arg} unless (@_);
	return see_config($_config->{$arg}, @_);
}

sub config
{
	return see_config($config, split('/', shift()));
}

sub allowed_ip
{
	my $ip = shift;
	return 0 if (scalar grep {
		$ip =~ /^$_$/;
	} @{config('deny_ip')});
	return 1 if (scalar grep {
		$ip =~ /^$_$/;
	} @{config('allow_ip')});
	return 0;
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
	my $dbh = DBI->connect('DBI:mysql:'.config('mysql/db'), config('mysql/user'), config('mysql/pass'), { mysql_enable_utf8 => 1 }) 
		or die "Could not connect to database: $DBI::errstr";
	$dbh->do("set character set utf8");
	$dbh->do("set names utf8");
	return $dbh;
}

sub strtoflags
{
	$_ = shift;
	my $regexp = config('flag_regexp');
	return m/$regexp/g;
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
