# build a list of unique parameters

use strict;
use Getopt::Long;
use URI;
use URI::Escape;
use URI::Split qw(uri_split uri_join);
use List::MoreUtils qw(uniq);

my @parameters;
my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config, qw(file|f=s help|?|h));

if ($config{help} || !%config) {
	_help();
	exit;
}

my $file = $config{file};
open (FH, "<", $file);

foreach my $line (<FH>){
	chomp $line;
	next if (!defined($line));
	#skip blank or commented out lines
	
	next if $line =~ m/^\#/;
	next if $line =~ m/^$/;
	
	my ($url, $comment) = split /\|/, $line;

	#change # to & to remove "fragment"
	$url =~ s/\#/\&/g;
	
	my $u = URI->new($url);
	my ($scheme, $domain, $path, $query, $frag) = uri_split($u);

	my %query_parameters = $u->query_form($u);

	push @parameters, keys %query_parameters;	
}


my @uniq = uniq @parameters;

print join("\n", @uniq), "\n";

sub _help {
	print<< "EOT";
-----------------------------------------------------------
Print out list of unique parameters from a list of urls in GSERPant.pl input format

-f|file ....... input file
-h|help ....... prints this help screen

No validation on the input
-----------------------------------------------------------
EOT
}