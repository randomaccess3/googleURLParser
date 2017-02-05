# Replace existing url parsing with the following script

use strict;
#use url::encode;

# on osx - cpan install URI::Split


use URI;
#use URI::QueryParam;
#use URI::URL;
use URI::Split qw(uri_split uri_join);

my $url; #= shift;
chomp $url;
my $url = "https://www.google.com.au/search?q=hello&oq=hello&aqs=chrome..69i64j69i59j0l4.2789j1j7&sourceid=chrome&ie=UTF-8"."#safe=on&q=next%20search&oq=next+sea";


#breaks if http:// or https:// not in front
#my $url = "https://www.google.com.au/search?q=hello+it%27s+me&oq=hello+it%27s+me&gs_l=serp.3...1295.2589.0.2686.8.6.0.0.0.0.0.0..0.0....0...1c.1.64.serp..8.0.0.S6E97hqYXGc";

my $u = URI->new($url);

my ($scheme, $domain, $path, $query, $frag) = uri_split($u);

#print $scheme."\n";
#print $domain."\n";


#remove slash from $path
#$path =~ s/\///g;
my $comment;

#add context to path
	$comment = "search" if $path eq "/search"; 
	$comment = "search" if $path eq "/webhp"; 
	$comment = "cache" if $path eq "/gen_204";
	$comment = "cache" if $path eq "/complete/search"; 
	$comment = "URL redirect" if $path eq "/url"; 
print $path."\t\t$comment\n";


#print $query."\n";
#pt($frag);

#$u->query_param($u); 
#print $u;
#for my $key ($u->query_param) {
   #print $key." = ".$u->query_param($key)."\n";
	#print "$key: ", join(", ", $u->query_param($key)), "\n";
 #}


my %frag_paramaters;
my @frag_params = split /\&/, $frag;
my $k;
foreach $k (@frag_params){
	my ($parameter, $value) = split /=/, $k;
	#$value = uri_unescape($value);
	$frag_paramaters{"$parameter"} = $value;
}

#printing values


if ($frag ne ""){
	print "Fragment: This is the actual search conducted\n";
	foreach my $k (sort keys %frag_paramaters){
		pv ($k,$frag_paramaters{$k});
	}
	pt("----------------------------");
}


my %params;
%params = $u->query_form($u);

print "Initial Search\n" if ($frag ne "");

foreach my $k (sort keys %params){
	pv ($k,$params{$k});
}


sub pt($){
	print "\|".shift."\|\n";
}

sub pv($$){
	print shift."\t\t".shift."\n";
}


# my $query = $u->query;
# #pt($query); 
 
#my $pathsegments = $u->path_segments;
# pt($pathsegments);

#my $host = $u->host;
# pt($host);
 
# my $frag   = $u->fragment;