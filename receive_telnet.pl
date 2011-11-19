#!/usr/bin/perl
package Globals;
use base 'Exporter';
our $dbh;
our @EXPORT_OK = qw($dbh);

package Server;
use warnings;
use strict;
use Common;
use Time::HiRes qw( usleep );
use Data::Dumper;

use base 'Net::Server::Fork';

sub process_request
{
	my $dbh = $Globals::dbh;
	my $self = shift;
	my $remote = $self->{server}->{peeraddr};
	if (!allowed_ip($remote)) {
		print "Segmentation fault\n";
		return;
	}
	print "Have you get some flags? Post it, please...\n";
	print "> ";
	my $count = 0;
	while( my $line = <STDIN> ) {
		$line =~ s/\r?\n$//;
		if ($line !~ /\S/) {
			print "Goodbye!\n";
			last;
		} else {
			my @f = strtoflags($line);
			$dbh->do('UPDATE stats SET processed=processed+?, last=NOW(), error=NULL WHERE app="receive"', undef, scalar(@f));
			if (!@f) {
				print "Not a flag\n";
			} else {
				foreach (@f) {
					my ($flag, $msg, $status) = addflag($dbh, $_, "telnet/$remote");
					$msg =~ s/<.*?>//g;
					print "$msg\n";
				}
			}
			print "> ";
		}
	}
	$dbh->disconnect();
}

package main;
use strict;
use warnings;
use Common;
use lib 'lib';

$Globals::dbh = connectdb();

sub tick {
	$dbh->do('INSERT INTO stats (app, last) VALUES ("receive", NOW()) ON DUPLICATE KEY UPDATE last=NOW(), error=NULL, addr=?', undef, config('telnet/host').':'.config('telnet/port'));
	alarm 40;
};

$SIG{ALRM} = \&tick;
tick;

Server->run(host => config('telnet/host'), port => config('telnet/port'));

