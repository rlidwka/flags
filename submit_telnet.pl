#!/usr/bin/perl

use strict;
use utf8;
use DBI;
use Data::Dumper;
use IO::Socket::INET;
use IO::Select;
use Common;

our $dbh = connectdb();

my @flags = @{$dbh->selectcol_arrayref('SELECT flag FROM flags WHERE resubmit=1 ORDER BY anstime ASC, addtime ASC LIMIT 10')};
exit if (!@flags);

our %answers = config('submit/answers');

sub addflag
{
	my ($flag, $result) = @_;
	my $resubmit = 1;
	my $isok = 0;
	foreach (keys %answers) {
		if (index($result, $_) != -1) {
			$resubmit = 0;
			$isok = $answers{$_};
			print "$flag - $result (correct = $isok)\n";
		}
	}
	print "$flag - $result (resubmitting)\n" if ($resubmit);
	$dbh->do('UPDATE flags SET anstime=NOW(), answer=?, resubmit=?, isok=? WHERE flag=?', undef, $result, $resubmit, $isok, $flag);
}

$| = 1;

my ($socket,$client_socket);

$socket = new IO::Socket::INET (
	PeerHost => '127.0.0.1',
	PeerPort => '8000',
	Proto => 'tcp',
) or die "sock error: $!\n";
$socket->blocking(0);

print "connected\n";

my $welcome = "> ";
my $s = IO::Select->new($socket);

my $cflag = shift @flags;
while(my @ready = $s->can_read(1)) {
	my $s = shift @ready;
	my $buf;
	if ($s->read($buf, 10240)) {
		if (index($buf, $welcome) != -1) {
			print $socket "$cflag\n";
			$socket->blocking(1);
			my $result = <$socket>;
			$result =~ s/^\s+|\s+$//g;
			$socket->blocking(0);
			addflag($cflag, $result);
			last if (!@flags);
			$cflag = shift @flags;
		}
	} else {
		last;
	}
}

$socket->close();
$dbh->disconnect();

