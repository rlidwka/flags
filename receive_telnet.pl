#!/usr/bin/perl
package Server;
use warnings;
use strict;
use vars qw($dbh);
use Common;
use Time::HiRes qw( usleep );
use Data::Dumper;

use base 'Net::Server::Fork';

sub process_request
{
	my $self = shift;
	my $remote = $self->{server}->{peeraddr};
	if (!allowed_ip($remote)) {
		print "Segmentation fault\n";
		return;
	}
	my $dbh = connectdb();
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

Server->run(port => 12321);
