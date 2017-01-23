#Program to store tests

use strict;

my %tests = (
	"https://www.google.com.au/?gfe_rd=cr&ei=-5Z-WN-lF6Tr8Af4lYnYDA" => "====================================================================================================\nhttps://www.google.com.au/?gfe_rd=cr&ei=-5Z-WN-lF6Tr8Af4lYnYDA\n====================================================================================================\nei=-5Z-WN-lF6Tr8Af4lYnYDA\t\t(2017-01-17T22:13:15 UTC) - Session Start Time - Set by Google's Time Servers to indicate the start of a session\ngfe_rd=cr\t\t(Country Redirect - Direct to your countries Google homepage)\n\n",
	"https://www.google.com.au/search?site=&source=hp&q=hello+world&oq=hello+world&gs_l=hp.3..35i39k1l2j0i67k1l3j0l5.1166.2397.0.2524.12.9.0.0.0.0.264.914.0j1j3.4.0....0...1c.1.64.hp..8.3.732.0..0i131k1.Iq3pvlQg1nI" => "====================================================================================================\nhttps://www.google.com.au/search?site=&source=hp&q=hello+world&oq=hello+world&gs_l=hp.3..35i39k1l2j0i67k1l3j0l5.1166.2397.0.2524.12.9.0.0.0.0.264.914.0j1j3.4.0....0...1c.1.64.hp..8.3.732.0..0i131k1.Iq3pvlQg1nI\n====================================================================================================\ngs_l=hp.3..35i39k1l2j0i67k1l3j0l5.1166.2397.0.2524.12.9.0.0.0.0.264.914.0j1j3.4.0....0...1c.1.64.hp..8.3.732.0..0i131k1.Iq3pvlQg1nI\t\t(keyboard [enter] key, Characters changed, more testing required-- IN PROGRESS\noq=hello+world\t\t(Query entered)\nq=hello+world\t\t(Query that Search results are returned for)\nsite=\t\tseen --NOT IMPLEMENTED\nsource=hp\t\t(Home Page - needs confirmationp)\n\n"
);



my $gserpent = "gserpent.pl";

#system (qq{$command});

#
#

#print $expected;

my $count = 0;

foreach my $url (keys %tests){
	$count++;
	my $command = "perl $gserpent -u \"$url\"";
	my $output = qx($command);
	my $expected = $tests{$url};
	
	if ($output eq $expected){
		print "$count. PASS\n";
	}
	else{
		print "$count. FAIL\n";
		print "Output:\n$output";
		print "Expected:\n$expected";
		
		#print_each_character($output);
		#print_each_character($expected);
	}
	
}




sub print_each_character($){
my $c;
my @chars = split //, shift;
foreach $c (@chars){
	print "'$c'\n";
}
print "------------------\n";
}