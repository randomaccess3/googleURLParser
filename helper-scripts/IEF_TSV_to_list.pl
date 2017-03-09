
# Convert TSV to list format
# input file is first argument

use strict;
use Getopt::Long;


my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config, qw(file|f=s help|?|h));

if ($config{help} || !%config) {
	_help();
	exit;
}
my $file = $config{file};
open (FH, "<", $file);

my $i=0;

#first line is the header
my $line = <FH>;
print "# Parsed TSV file: $file\n";


foreach $line (<FH>){
	chomp $line;
	my @args = split /\t/, $line;
	

	my $search_term = $args[1];
	my $url = $args[2];
	my $date = $args[3];
	
	#skip non searches
	next if $url =~ m/http[s]:\/\/support\.google/;
	
	if ($date ne ""){
		print "$url| Search for $search_term at $date UTC\n";
	}
	else{
		print "$url| Search for $search_term\n";
	}
	
}
close(FH);

#TSV output fields
# Record	
# Search Term	
# URL	
# Date/Time - (UTC) (dd/MM/yyyy)	
# Date/Time - Local Time (yyyy-mm-dd)	
# Original Search Query	
# Search Session Start Date/Time - (UTC) (dd/MM/yyyy)	
# Web Page Title	
# Previous Queries	
# Artifact	
# Artifact 
# ID	
# Source	
# Located At	
# Evidence Number




sub _help {
	print<< "EOT";
-----------------------------------------------------------
Converts IEF TSV format into list format for GSERPant

-f|file ....... input file
-h|help ....... prints this help screen

No validation on the input
-----------------------------------------------------------
EOT
}