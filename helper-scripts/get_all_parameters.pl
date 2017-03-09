# build a list of unique parameters

use strict;
use Getopt::Long;
use URI::Escape;

my %parameters = {};
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
	next if $line =~ m/^\#/;
	next if $line =~ m/^$/;
	
	my ($url, $comment) = split /\|/, $line;
	
	$url =~ s/^http[s]:\/\///g if ($url =~ m/^http[s]:\/\//);
	
	#remove http://www.google.com.*/
	my ($google, @rest) = split /\//, $url;
	$url = join('\/', @rest) if ($rest[0]);
	$url =~ s/\\\//\//g;
		
	#extract the term between google.com/___?
	$url =~ s/(.*)\?//g;	

	$url =~ s/\&|\#/\n/g;	
	#remove spaces
	$url =~ s/ //g;

	#print $url."\n";
	#<STDIN>;
	
	next if $line =~ m/^$/;
	
	my @urlentries = split /\n/, $url;
	
		
	#load hash with parameters
	my $u;
	foreach $u (@urlentries){
		#print $u."\n";
		$u =~ m/(.*)=(.*)/;
		$parameters{$1} = 1;
		#print $1."\n";
		#$parameters{$1} = uri_unescape($2) if ($u =~ m/(.*)=(.*)/); # may need to run uri_unescape twice
	}
	#<STDIN>;
	
}

my @vals = sort keys %parameters;
foreach my $v (@vals){
	print $v."\n";
}


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