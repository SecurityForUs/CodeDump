#!/usr/bin/perl -w

use Net::SNMP;

my $hostname 	= $ARGV[0] if defined $ARGV[0];
my $port	= $ARGV[1] if defined $ARGV[1];
my $comm	= $ARGV[2] if defined $ARGV[2];
my $ver		= $ARGV[3] if defined $ARGV[3];

my $oid_bwi = ".1.3.6.1.4.1.8072.1.3.2.4.1.2.7.118.105.114.116.98.119.105.1";
my $oid_bwo = ".1.3.6.1.4.1.8072.1.3.2.4.1.2.7.118.105.114.116.98.119.111.1";

my ($session, $error) = Net::SNMP->session(
	-hostname	=> $hostname,
	-port		=> $port,
	-version	=> $ver,
	-community	=> $comm
);

if(!defined($session)){
	printf("ERROR: %s\n", $error);
	exit 1;
}

my $res = $session->get_request(
	-varbindList => [$oid_bwi, $oid_bwo]
);

if(!defined($res)){
	printf("ERROR [res]: %s\n", $session->error);
	$session->close;
	exit 1;
}

printf("in:%s out:%s", $res->{$oid_bwi}, $res->{$oid_bwo});

$session->close;
