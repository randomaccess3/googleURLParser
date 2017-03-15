#print all the parameters and their available values from a list


use strict;
use Getopt::Long;
use URI;

use URI::URL;
use URI::Escape;
use URI::Split qw(uri_split uri_join);
use List::MoreUtils qw(uniq);

my %parameters;
my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config, qw(file|f=s param|p=s help|?|h));

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
	#$url =~ s/\#/\&/g;
	
	my $u = URI->new($url);
	my ($scheme, $domain, $path, $query, $frag) = uri_split($u);

	#my %query_parameters = $u->query_form($u);
	#print $query."\n";
	#my $v = keys %query_parameters;
	#print $v. "\n";
	
	#foreach my $k (keys %query_parameters){
	#	print $query_parameters{$k}."\n";
	#	push( @{ $parameters { $k } }, $query_parameters{$k}); 
	#}
	my $f;
	my @q = split /&/, $query;
	foreach my $f (@q){
		$f =~ m/(.*)=(.*)/;
		my $key = $1;
		my $value = $2;
		push( @{ $parameters { $key } }, $value); 
	}



	
	#split frag parameters
	my @fragments = split /&/, $frag;
	foreach my $f (@fragments){
		$f =~ m/(.*)=(.*)/;
		my $key = $1;
		my $value = $2;
		push( @{ $parameters { $key } }, $value); 
	}
	#print "\n";
		
	
}


#use Data::Dumper;
#print Dumper \%parameters;
my @uniq; 
print "-------------------\n";
if ($config{param}){
   my $k = $config{param};
   print "$k=\n";
   my @vals = @{$parameters{$k}};
   @uniq = uniq @vals;
   print join("\n", @uniq), "\n";
   print "-------------------\n";
}
else{
	
	foreach my $k (keys %parameters) {
		print "$k=\n";
		my @vals = @{$parameters{$k}};
		@uniq = uniq @vals;
		print join("\n", @uniq), "\n";
		print "-------------------\n";
	}
}






sub _help {
	print<< "EOT";
-----------------------------------------------------------
Print out list of unique parameters from a list of urls in GSERPant.pl input format

-f|file ....... input file
-p|param ...... specify parameter
-h|help ....... prints this help screen

No validation on the input
-----------------------------------------------------------
EOT
}