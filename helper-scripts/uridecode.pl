#!/usr/bin/perl

#usage uridecode "url"

use strict;
use URI::Escape;

my $url = shift;

printEqDivider();
print $url."\n";
printEqDivider();
$url = uri_unescape($url);
print $url."\n";
print "\n";

sub printEqDivider{
	my $n = 150;
	my $character = '=';
	my $text =~ s/^(.*)/$character x $n . $1/mge;
	print $text."\n";
}


