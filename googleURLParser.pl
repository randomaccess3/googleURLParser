#if you run it on nix/osx it wont delete the temp file yet

#Version History
# 20161222 - initial commit
# 20161223 - add psi, start parsing and additional url from iacis listserv 
#
#
#
#
#To Install
# ppm install URI (which I think comes with perl now)
# requires python 2.7 installed to run the EI parser
# Automatically downloads the python EI parser if its not detected


#To do ; put in download code for EI parser 
# separate # from URL as it denotes a second search


#Research
# http://www.ramdynamo.com/2014/03/google-gferdcr-url-mystery-revealed.html



#Original Query - If the original query is less than the q value then it's possible that the user has clicked on a suggested post - need more research on the topic





use Data::Dumper;
use URI::Escape;
use strict;

my 	 @urls = ();
push @urls, "https://www.google.com.au/?gfe_rd=cr&ei=u_paWP7NHKbr8Af0vYcI"; #go to Google homepage, in chrome, safe search on, not logged in
push @urls, "https://www.google.com.au/search?q=perl+scalars&oq=perl+scalars&aqs=chrome.0.0l6.4792j1j7&sourceid=chrome&ie=UTF-8";   #search in Google Chrome search bar for perl scalars, safe search on, not logged in
push @urls, "https://www.google.com.au/search?q=push+array+perl&oq=push+&aqs=chrome.2.69i57j0l5.5225j1j7&sourceid=chrome&ie=UTF-8"; #search in Google Chrome search bar for push array perl, safe search on, typed partial then selected from suggested, , not logged in
push @urls, "http://www.google.com/search?ie=UTF-8&oe=UTF-8&sourceid=navclient&gfns=1&q=target"; #taken from https://moz.com/blog/the-ultimate-guide-to-the-google-search-parameters, "gfns=1the link will take you to the first (organic) result for that term"
push @urls, "https://www.google.com/search?q=vonnegut&hl=en&biw=1440&bih=728&site=webhp&ei=lTHWVqawIJikjwPj1J7ADA&start=140&sa=N&bav=on.2,or.&bvm=bv.115946447,d.cGc&fp=1a23df61796ce349&tch=1&ech=1&psi=ajHWVq-dGcP8jwP6w4G4Aw.1456877930638.29"; #provided in email on iacis listserv
my $url;

my $count = 0;
foreach $url (@urls){	
	$count++;
	printEqDivider();
	print $count.": ".$url."\n";
	printEqDivider();
	
	parse_URL($url);
	print "\n";
	#<STDIN>;
}
printDivider();

sub parse_URL($){
	my @alerts = "";
	my %parameters = {};
	my $url = shift;
	
	#remove http://www.google.com.*/.*?
	$url =~ s/^.*google.*\?//g;
	#Escape characters
	my $url = uri_unescape($url);
	$url = uri_unescape($url); #required to run twice as sometimes not everything unescapes
	
	$url =~ s/\?/\n/g;
	$url =~ s/\&/\n/g;
	
	#print "URL:".$url."\n";
	my @urlentries = split /\n/, $url;
	
	#load hash with parameters
	my $u;
	foreach $u (@urlentries){
		$parameters{$1} = $2 if ($u =~ m/(.*)=(.*)/g);
	}

	$u = "";
	
	#If the q and oq exist and arent equal
	if (exists($parameters{"q"}) && (exists($parameters{"oq"})) && ($parameters{"q"} ne $parameters{"oq"})){
			push @alerts, "Either additional search, or suggested search was suggested from search bar (chrome)";
	} 
	
	foreach $u (keys %parameters){
		
		#Unsure why the hash has a HASH -> undef entry in it, this line skips it
		next if (!defined($parameters{$u}));
		
		$parameters{$u} = parseEI($parameters{$u}) if ($u eq "ei");
		$parameters{$u} = parseGFE_RD($parameters{$u}) if ($u eq "gfe_rd");
		$parameters{$u} = parseGFNS($parameters{$u}) if ($u eq "gfns");
		$parameters{$u} = parsePSI($parameters{$u}) if ($u eq "psi");
		$parameters{$u} = parseStart($parameters{$u}) if ($u eq "start");
		$parameters{$u} .= "\t(Original Query)" if ($u eq "oq");
		$parameters{$u} .= "\t(Searched Query)" if ($u eq "q");
		
		print "$u=$parameters{$u}\n";
		
	}

	#printDivider();
	#print scalar(@alerts)."\n";
	#printDivider();
	
	if (scalar(@alerts) > 1) {
		printDivider();
		print "Alerts:";
		foreach (@alerts) {
			print $_."\n";
		}
	}
	@alerts = "";
	return;
}

sub parsePSI($){
	my $psi = shift;
	my ($ei, $unix, $unknown) = split /\./, $psi;
	
	my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";
	system (qq{$command});
	$ei = readTemp("temp")." UTC";
	system (qq{del temp});
	
	#$unix last three digits removed to make it a unix timestamp. Should match the EI timestamp
	$unix = substr($unix, 0, -3);
	$unix = gmtime($unix);
	
	
	$psi .= "\t\t($ei,$unix,$unknown)";
	
	return $psi;
}

sub parseEI($){
	my $ei = shift;
	my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";
	system (qq{$command});
	$ei .= "\t\t(".readTemp("temp")." UTC) - Session Start Time - Set by Google's Time Servers to indicate the start of a session";
	system (qq{del temp});
	return $ei;
}

sub parseGFE_RD($){
	my $gfe_rd = shift;
	if ($gfe_rd eq "cr"){
		return "$gfe_rd\t\t(Country Redirect - Direct to your countries Google homepage)"
	}
	return $gfe_rd;
}

sub parseGFNS($){
	my $gfns = shift;
	if ($gfns eq "1"){
		return "$gfns\t\t(I'm feeling lucky - first organic result will be accessed)"
	}
}

sub parseStart($){
# Determines page that the search is on
# ie start=140 = page 15, so divide by 10 + 1
	my $start = shift;
	$start.= "\t\t(Page ".(($start/10)+1).")";
	return $start;
}

sub readTemp($){
	my $temp = shift;
	my $line;
	open(my $fh, '<', $temp) or die "cannot open file $temp";
	{
			local $/;
			$line = <$fh>;
	}
	close($fh);
	chomp $line;
	return $line;
}

sub printEqDivider{
	my $n = 150;
	my $character = '=';
	my $text =~ s/^(.*)/$character x $n . $1/mge;
	print $text."\n";
}

sub printDivider{
	my $n = 150;
	my $character = '-';
	my $text =~ s/^(.*)/$character x $n . $1/mge;
	print $text."\n";
}