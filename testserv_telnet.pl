#!/usr/bin/perl
package Server;
use warnings;
use strict;
use Time::HiRes qw( usleep );

use base 'Net::Server::Fork';

sub check
{
	return int(sqrt($_[0]))**2==$_[0];
}

sub process_request
{
	my $self = shift;
	print "Flag checker... do you know some perfect square numbers?\n";
	print "> ";
	my $count = 0;
	while( my $line = <STDIN> ) {
		$line =~ s/\r?\n$//;
		usleep(200000);
		if ($line !~ /\S/) {
			print "Goodbye!\n";
			last;
		} elsif ($count++ > 7) {
			print "Too many flags\n";
			last;
		} elsif ($line =~ /[^\d]/) {
			print "Not a flag\n";
		} elsif (check(int $line)) {
			print "Accepted\n";
		} else {
			print "Rejected\n";
		}
		print "> ";
	}
}

package main;
use strict;
use warnings;

use lib 'lib';

Server->run(port => 8008);
