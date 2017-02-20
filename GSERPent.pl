#if you run it on nix/osx it wont delete the temp file yet

#Created by Phill Moore - randomaccess3@gmail.com

#Version History
# 20161222 	- initial commit
# 20161223 	- add psi, start parsing and additional url from iacis listserv 
#			- added redirect link and url parameter parsing/note
# 20161225 	- add safe, pws
# 20161226	- add ust (time parameter)
#			- option for input from a file
#			- cd  (results link position)
# 20170104  - fixed spacing error in file parsing
#			- ie parameter
#			- add bih/biw parameter
#			- started rlz parameter
#			- added tbm
# 20170105  - updated GWS_RD, added client, formatting, sig2
#			- added stubs for cad, esrc, rct, sa, uact, usg, web
# 20170107  - add data to source parsing
# 20170109  - fixed bug with regards to the ? seperator, added stub for psig2, added additional source data
#			- added table output (more work required)
#			- tbs, bvm stub, ion, updated some parameters with additional terms
# 20170110  - espv stub, site, psi comments, gs_l comments, aqs comments
#			- update client (android), sourceid (mobile)
# 20170111  - add OS X install instructions
#			- add option to just show provided parameter
#			- started gs_l, added cr value
# 20170115  - added opera to client and sourceid
#			- fixed bug in printing alerts, added additional decoding to aqs parameter
#			- further research into gs_l
#			- commented out rm temp to avoid errors on windows
# 20170116  - researched sa parameter, added hl, filter
# 20170122  - added timezone-modifier commandline argument
#			- added alerts for UST parameter
#			- updated aqs parameter
# 20170123	- moved EI note to alert, update biw, bih
# 20170220  - added URI package instead of manual parsing
#			- updated alerts for ust
#			- added ved parsing, to be completed

my $VERSION = "20170220";

#To Install Windows
# ppm install URI (which I think comes with perl now)
# ppm install Text-ASCIITable
# requires python 2.7 installed to run the EI parser - https://raw.githubusercontent.com/cheeky4n6monkey/4n6-scripts/master/google-ei-time.py
# Requires cheeky4n6monkey/4n6-scripts/master/google-ei-time to be in the same folder
# Requires https://github.com/TomAnthony/ved-decoder/ which is an updated forked parser originally written by Benjamin Schulz (https://github.com/beschulz)
# pip install protobuf to use the ved-decoder


#To Install OS X
# cpan Text::ASCIITable

#To do ; put in download code for EI parser and ved decoder, updated ved decoder to use install protobuf rather than lib directory
# separate # from URL as it denotes a second search
# probably port to python

# Known bug
# Doesnt deal with # in search
# Doesn't remove +'s in q or oq value

# Research
# http://www.ramdynamo.com/2014/03/google-gferdcr-url-mystery-revealed.html
# https://cs.chromium.org/chromium/src/chrome/common/search/instant_types.h?q=aqs&sq=package:chromium&dr=C&l=181
# https://gist.github.com/sshay77/4b1f6616a7afabc1ce2a


# Old VED/New VED - https://deedpolloffice.com/blog/articles/decoding-ved-parameter
#	Ved decoder - https://github.com/TomAnthony/ved-decoder


#Original Query - If the original query is less than the q value then it's possible that the user has clicked on a suggested post - need more research on the topic






use Data::Dumper;
use URI;
use URI::Escape;
use URI::Split qw(uri_split uri_join);
use strict;

use Getopt::Long;
use File::Spec;

use Text::ASCIITable;



my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config,qw(url|u=s file|f=s param|p=s table|t timezone|tz=s help|?|h));


our @alerts = ();
our $timezone_modifier = 0;
our %parameters = {};


if ($config{timezone}){
	$timezone_modifier = $config{timezone};
	$timezone_modifier =~ s/\+//;	#remove the + if the user includes it, there's no other validation
}

if ($config{help} || !%config) {
	_help();
	exit;
}

my $url; 
if ($config{url}) {
	$url = $config{url};
	printEqDivider();
	print $url."\n";
	printEqDivider();
	parse_URL($url);
	print "\n";
}
elsif ($config {file}){
	my $count = 0;
	open(FH,"<",$config{file});
	foreach my $line (<FH>){
		chomp $line;

		next if ($line =~ m/^\#.*/);
		next if ($line =~ m/^$/);
		my $comment;
		($url,$comment) = split /\|/, $line;
		$count++;
		printEqDivider();
		print $count.": ".$url."\n";
		print "Comment: $comment\n" if ($comment);
		printEqDivider();
	
		parse_URL($url);
		print "\n";
	}
	close(FH);
	printDivider();
}
else {
		return undef;
}

sub parse_URL($){
	#my @alerts = "";
	
	my $url = shift;
	
	my $u = URI->new($url);
	my ($scheme, $domain, $path, $query, $frag) = uri_split($u);
	
	# load parameters (split by &)
	%parameters = $u->query_form($u);

	
	push @alerts, "Redirect link, usually indicating opening in new tab/window. Query will most often be blank" if ($path eq "/url");
	push @alerts, "Imgres shows up if you right click on a picture in image search and save the url. The URL doesn't appear in the task bar or internet history" if ($path eq "/imgres");
	push @alerts, "URL taken from cache - haven't tested the parsing" if ($path eq "/gen_204" || $path eq "/complete/search");	
	
	
	# If a fragment (hash) exists in the URL then the previous search was before the hash and the current search was in the q after the hash
	# Sometimes google won't add the #, and just recreates the query again
	push @alerts, "# indicates second search - not implemented currently.\nFragment = $frag" if ($frag);


	#If the q and oq exist and arent equal
	if (exists($parameters{"q"}) && (exists($parameters{"oq"})) && ($parameters{"q"} ne $parameters{"oq"})){
		push @alerts, "Regarding the q and oq parametrs: Either additional search, or suggested search was selected from search bar (tested on chrome)";
	} 
	
	# UST parameter appears to relate to when Gmail was opened if it's in a redirect link from gmail	
	if (exists($parameters{"ust"})){
		push @alerts, "UST: In testing I have found the UST timestamp to be a Google-server timestamp indicating 24 hours after Gmail was opened." if ($parameters{"source"} eq "gmail");
		push @alerts, "UST: In testing I have found the UST timestamp to be a Google-server timestamp indicating 24 hours after when the image search was conducted." if ($parameters{"source"} eq "images");
	}
	
	
	foreach my $u (sort keys %parameters){
		
		#Unsure why the hash has a HASH -> undef entry in it, this line skips it
		next if (!defined($parameters{$u}));
		
		# If -p option used then skip if the current parameter doesn't match provided parameter
		next if ($config{param} && $config{param} ne $u);
		 
		# Sends the parameter value to the subroutine for parsing
		# result is returned and printed on a new line with the parameter name
		$parameters{$u} = parse_EI($parameters{$u}) if ($u eq "ei");
		$parameters{$u} = parse_GFE_RD($parameters{$u}) if ($u eq "gfe_rd");
		$parameters{$u} = parse_GWS_RD($parameters{$u}) if ($u eq "gws_rd");
		$parameters{$u} = parse_GFNS($parameters{$u}) if ($u eq "gfns");
		$parameters{$u} = parse_PSI($parameters{$u}) if ($u eq "psi");
		$parameters{$u} = parse_Start($parameters{$u}) if ($u eq "start");
		$parameters{$u} = parse_pws($parameters{$u}) if ($u eq "pws");
		$parameters{$u} = parse_safe($parameters{$u}) if ($u eq "safe");
		$parameters{$u} = parse_ust($parameters{$u}) if ($u eq "ust");
		$parameters{$u} = parse_zx($parameters{$u}) if ($u eq "zx");
		$parameters{$u} = parse_VED($parameters{$u}) if ($u eq "ved");
		$parameters{$u} = parse_sourceid($parameters{$u}) if ($u eq "sourceid");
		$parameters{$u} = parse_aqs($parameters{$u}) if ($u eq "aqs");
		$parameters{$u} = parse_rlz($parameters{$u}) if ($u eq "rlz");	
		$parameters{$u} = parse_tbm($parameters{$u}) if ($u eq "tbm");	
		$parameters{$u} = parse_client($parameters{$u}) if ($u eq "client");
		$parameters{$u} = parse_sclient($parameters{$u}) if ($u eq "sclient");
		$parameters{$u} = parse_q($parameters{$u}) if ($u eq "q");	
		$parameters{$u} = parse_cad($parameters{$u}) if ($u eq "cad");	
		$parameters{$u} = parse_esrc($parameters{$u}) if ($u eq "esrc");	
		$parameters{$u} = parse_rct($parameters{$u}) if ($u eq "rct");	
		$parameters{$u} = parse_uact($parameters{$u}) if ($u eq "uact");	
		$parameters{$u} = parse_sa($parameters{$u}) if ($u eq "sa");
		$parameters{$u} = parse_usg($parameters{$u}) if ($u eq "usg");		
		$parameters{$u} = parse_source($parameters{$u}) if ($u eq "source");		
		$parameters{$u} = parse_psig($parameters{$u}) if ($u eq "psig");
		$parameters{$u} = parse_gs_l($parameters{$u}) if ($u eq "gs_l");
		$parameters{$u} = parse_tbs($parameters{$u}) if ($u eq "tbs");
		$parameters{$u} = parse_bvm($parameters{$u}) if ($u eq "bvm");
		$parameters{$u} = parse_site($parameters{$u}) if ($u eq "site");
		$parameters{$u} = parse_ion($parameters{$u}) if ($u eq "ion");
		$parameters{$u} = parse_espv($parameters{$u}) if ($u eq "espv");
		$parameters{$u} = parse_cr($parameters{$u}) if ($u eq "cr");
		$parameters{$u} = parse_filter($parameters{$u}) if ($u eq "filter");
		$parameters{$u} = parse_dpr($parameters{$u}) if ($u eq "dpr");
		$parameters{$u} .= "\t\t(A user was logged in)" if ($u eq "sig2"); # https://moz.com/blog/decoding-googles-referral-string-or-how-i-survived-secure-search
		$parameters{$u} .= "\t\t(Browser Window Height)" if ($u eq "bih"); #https://www.reddit.com/r/explainlikeimfive/comments/2ecozy/eli5_when_you_search_for_something_on_google_the/
		$parameters{$u} .= "\t\t(Browser Window Width)" if ($u eq "biw");
		$parameters{$u} .= "\t\t(Link number - further testing required)" if ($u eq "cd");   #https://moz.com/blog/tracking-organic-ranking-in-google-analytics-with-custom-variables
		$parameters{$u} .= "\t\t\(Query entered)" if ($u eq "oq");
		$parameters{$u} .= "\t\t(Input Encoding)" if ($u eq "ie");   #joostdevalk.nl - google websearch parameters
		$parameters{$u} .= "\t\t(Output Encoding)" if ($u eq "oe");   #joostdevalk.nl - google websearch parameters
		$parameters{$u} .= "\t\t(Specifies the interface language)" if ($u eq "hl");   #joostdevalk.nl - google websearch parameters
		$parameters{$u} .= "\t\t(Show results for location)" if ($u eq "gl");   #joostdevalk.nl - google websearch parameters
		$parameters{$u} .= "\t\t(Usually indicates that this was opened in a new tab/window from the Search Results page)" if ($u eq "url");
		
		print "$u=$parameters{$u}\n" if (!$config{table});
		
	}
	
	#printDivider();
	#print scalar(@alerts)."\n";
	#printDivider();
	
	if ($config{table}){
		my $t = Text::ASCIITable->new();
		$t->setCols('Parameter','Value','Comment');
		$t->alignCol('Parameter','left');
		$t->alignCol('Value','left');
		$t->alignCol('Comment','left');
		
		#load new hash and move the key from name, value+comment, to name+value, comment
		my $param_name;
		foreach $param_name (sort keys %parameters){
			next if (!defined($parameters{$param_name}));	
			$parameters{$param_name} =~ s/\t\t/\t/g; #replace the double tab with a single tab
			my ($param_value, $param_comment) = split /\t/, $parameters{$param_name}; #split the parameter value with the comment
			$t->addRow($param_name,$param_value,$param_comment);
		}
		print $t;
	}
	
	#print "Num alerts: ".scalar(@alerts)."\n";
	
	if (scalar(@alerts) > 0) {
		printDivider();
		print "Alerts:\n";
		foreach (@alerts) {
			print $_."\n";
		}
	}
	@alerts = "";
	return;
}

# found when examining the cache files. so far seen on chrome havent tested anything else
# it seems that the two timestamps are different but not sure why
# may relate to multiple searches in the same session
sub parse_PSI($){
	my $psi = shift;
	my ($ei, $unix, $unknown) = split /\./, $psi;
	
	
	my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";
	system (qq{$command});
	$ei = readTemp("temp")." UTC";
	system (qq{del temp});
	#system (qq{rm temp});
	
	#$unix last three digits removed to make it a unix timestamp. Should match the EI timestamp
	$unix = substr($unix, 0, -3);
	$unix = gmtime($unix);
	
	$psi .= "\t\t($ei,$unix,$unknown)";
	return $psi;
}

#indicates the start of a session
#can reliably get this value if you go to Google's homepage on chrome
sub parse_EI($){
	my $ei = shift;
	
	my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";
	#print $command."\n";
	system (qq{$command});
	$ei .= "\t\t(".readTemp("temp")." UTC) - Session Start Time";
	push @alerts, "EI: Set by Google's Time Servers to indicate the start of a session. If found in cache this isn't always reliable";
	system (qq{del temp});
	return $ei;
}

sub parse_GFE_RD($){
	my $gfe_rd = shift;
	return "$gfe_rd\t\t(Country Redirect - Direct to your countries Google homepage)" if ($gfe_rd eq "cr");
	return $gfe_rd;
}

sub parse_q($){
	my $q = shift;
	# when clicking on links to youtube subscribed videos in gmail the url is parsed uri encoded in a q= parameter
	# Theres no real harm in unescaping multiple times? I guess unless someone searches using %'s, further testing required
	$q = uri_unescape($q); 
	return "$q\t\t(Query not passed to search URL)" if ($q eq "");
	return "$q\t\t(Query that Search results are returned for)";

}


# On Chrome
# Go to google.com - redirect to .com.au and no gws_RD
# go to google.com.au - no EI or gfe_rd, but gws_rd
# go to https://www.google.com.au - no parameters, just search term
# On IE
# Similar, except when searching from the URL bar you get the cr,ssl value
sub parse_GWS_RD($){
	my $gws_rd = shift;
	return "$gws_rd\t\t(Redirect to SSL site)" if ($gws_rd eq "ssl");
	return "$gws_rd\t\t(Country Redirect and Redirect to SSL site - so far only seen on IE)" if ($gws_rd eq "cr,ssl");
	return $gws_rd;
}



sub parse_GFNS($){
	my $gfns = shift;
	return "$gfns\t\t(I'm feeling lucky - first organic result will be accessed)" if ($gfns eq "1");
	return $gfns;
}

sub parse_sourceid($){
	my $sourceid = shift;
	return "$sourceid\t\t(Google Chrome)" if ($sourceid eq "chrome");
	return "$sourceid\t\t(Google Chrome - Instant Enabled)" if ($sourceid eq "chrome-instant");
	return "$sourceid\t\t(Google Chrome - Instant Enabled? unsure)" if ($sourceid eq "chrome-psyapi2");
	return "$sourceid\t\t(Google Chrome Mobile)" if ($sourceid eq "chrome-mobile");
	return "$sourceid\t\t(Opera)" if ($sourceid eq "opera");
}

#identified firefox-a on https://googlesystem.blogspot.com.au/2006/07/meaning-of-parameters-in-google-query.html, but haven't researched it yet

sub parse_client($){
	my $client = shift;
	return "$client\t\t(Mozilla Firefox)" if ($client eq "firefox-b");
	return "$client\t\t(Mozilla Firefox - Search using Address Bar)" if ($client eq "firefox-b-ab");
	return "$client\t\t(Chrome for Android)" if ($client eq "ms-android-google");
	return "$client\t\t(Opera)" if ($client eq "opera");
	return $client
}

# unsure what it means, seen on chrome and ie so far
sub parse_sclient($){
	my $sclient = shift;
	return "$sclient\t\t(seen, not sure)" if ($sclient eq "psy-ab");
	return $sclient
}

# seen chrome, blank when search from google homepage
sub parse_site($){
	my $site = shift;
	return "$site\t\tseen --NOT IMPLEMENTED" if ($site eq "");
	return $site;
}


# http://superuser.com/questions/653295/what-is-the-aqs-parameter-in-google-search-query
# Confirmed that the third parameter within this parameter (split by .'s) is number of milliseconds from initial keypress - if it exists
# so far can get this value when typing in chrome, but not in google search box on homepage
# Therefore if aqs is identified it would only relate to the q or oq values prior to the #
# aqs stands for Assisted query stats 
# https://cs.chromium.org/chromium/src/chrome/common/search/instant_types.h
# From the looks of things this is Chrome only - it appears when you perform a search offline through the search bar. Doesn't appear in other browsers
# HOST BASED PARAMETER
# Field 1 indicates whether the user selected an item from the dropdown list (whether they selected it themselves or it was autofilled)
# if parameter doesn't have the time value, then that seems to indicate the the user had selected a word in another tab and selected "search Google for ____"
sub parse_aqs($){
	my $aqs = shift;
	my @args = split /\./, $aqs;
	my $comment;
		
	if ($args[1] ne ""){
		$comment .= "(Item ".($args[1]+1). " selected)";
		push @alerts, "AQS: I've found this means that the browser autofilled the query and the user didn't delete it" if ($args[1] eq "0");
	}
	
	if (@args < 4){
		my $q = $parameters{"q"};
		$comment .= "(User right clicked on the word $q and selected \"Search Google for $q\" from the context menu in a Chromium-based browser)";
	}
	
	
	if (exists $args[3]){
		(my $time, my @other) = split /j/, $args[3];
		$comment .= "($time milliseconds from first keypress to search. Other parameters unknown)";
	}
	
	$comment =~ s/\)\(/, /g;
	
	return "$aqs\t\t$comment";
}

#https://www.reddit.com/r/explainlikeimfive/comments/2ecozy/eli5_when_you_search_for_something_on_google_the/
# language and encoding information
sub parse_rlz($){
	my $rlz = shift;
	return $rlz."\t\t--not implemented";
}

# Search engine type
sub parse_tbm($){
	my $tbm = shift;
	return "$tbm\t\t(Image Search}" if ($tbm eq "isch");
	return "$tbm\t\t(Video Search}" if ($tbm eq "vid");
	return "$tbm\t\t(News Search}" if ($tbm eq "nws");
	return "$tbm\t\t(Books Search}" if ($tbm eq "books");
	return "$tbm\t\t(Shopping Search}" if ($tbm eq "shopping");
	return $tbm;
}

sub parse_Start($){
# Determines page that the search is on
# ie start=140 = page 15, so divide by 10 + 1
	my $start = shift;
	$start.= "\t\t(Page ".(($start/10)+1).")";
	return $start;
}


sub parse_pws($){
	my $pws = shift;
	return "$pws\t\t(Hide private results)" if ($pws eq "0");
	return "$pws\t\t(Show all results)" if ($pws eq "1");
}


# saw strict when I had it activated in the options whilst logged in, haven't seen it otherwise
# off and active are more likely when you change it for the particular session using the dropdown menu
# further testing required
sub parse_safe($){
	my $safe = shift;
	return "$safe\t\t(Safe search off)" if ($safe eq "off");
	return "$safe\t\t(Safe search on)" if ($safe eq "active");
	return "$safe\t\t(Safe search on)" if ($safe eq "strict");
}


# Limited testing of UST appears that its a timestamp that's generated when the results are returned
# So if you open a search page (I've tested for image search so far), then leave the page open for a while
# You can select different images and the black box will appear around them but the redirect link time will reflect
# the time of the original search
# So far this time has only appeared when you select a picture and then click on the "Visit page" or "View Image" boxes
# Selecting the image itself straight off the search page doesn't appear to generate this value but havent looked in the internet
# history, just right click, saved link and parsed
# I've also found it on links opened in Gmail that open in a new tab. They usually use a google redirect link and the UST timestamp indicates when
# Gmail was opened (but it appears to be 24 hours ahead)
sub parse_ust($){
	my $ust = shift;
 #first 10 characters are a unix timestamp
	my $unix = substr($ust, 0, 10);
	my $timezone = $timezone_modifier * (60 * 60);
	$unix = gmtime($unix+$timezone);
	
	return "$ust\t\t($unix UTC$timezone_modifier)" if ($timezone_modifier =~ /-/);
	return "$ust\t\t($unix UTC+$timezone_modifier)";
	
}

sub parse_zx($){
	my $zx = shift;
 #first 10 characters are a unix timestamp
	my $unix = substr($zx, 0, 10);

	my $timezone = $timezone_modifier * (60 * 60);
	$unix = gmtime($unix+$timezone);
	
	return "$zx\t\t($unix UTC$timezone_modifier - unsure what it represents)" if ($timezone_modifier =~ /-/);
	return "$zx\t\t($unix UTC+$timezone_modifier - unsure what it represents)";
}


# so far have only seen source = web - havent tested on mobile
# seen gmail when clicking a youtube subscription link from gmail
# seen images when clicking on a "visit page" link in image search
# did a search and changed the returned results from date A to date B, saw source=lnt
# sometimes I see source=hp not sure why, may indicate the user searched from the homepage
sub parse_source($){
	my $source = shift;
	return "$source\t\t(Web - standard browser search)" if ($source eq "web");
	return "$source\t\t(Clicked on link from Gmail)" if ($source eq "gmail");
	return "$source\t\t(Clicked link from Image Search)" if ($source eq "images");
	return "$source\t\t(seen - Unknown)" if ($source eq "lnt");
	return "$source\t\t(Home Page - needs confirmationp)" if ($source eq "hp"); #may indicate the user searched from the homepage ie images.google.com
	return "$source\t\t(User selected redirect from other Google page -- needs confirmation)" if ($source eq "lnms"); # may indicate user went from one google search type to another ie search-->images	
	return "$source\t\t(Unknown)";
}


# Ex: tbs=qdr:h,ctr:countryAU&cr=countryAU - past hour in australia
# qdr - h (hour) d (day) m (month) y (year) w (week) 
# tbs=qdr:w,sbd:1 - past week sort by date
# qdr:d - past day
# Ex: tbs=li:1   - verbatim
# Ex: ctr:countryAU&cr=countryAU - just australia

#tbs=cdr%3A1%2Ccd_min%3A1%2F01%2F2017%2Ccd_max%3A7%2F01%2F2017 - cdr:1,cd_min:1/01/2017,cd_max:7/01/2017 - selected time period (this is uri encoded)

# Verbatim results appears to remove other tbs parameters
# Options from the Tools drop down menu
sub parse_tbs($){
	my $tbs = shift;
	my @vals = split /,/, $tbs;

	return ($tbs .= "\t\t(Filter by a specific time period)") if ($tbs  =~ m/cdr:1/);
	
	$tbs .= "\t\t";
	foreach my $v (@vals){
		#print "v - $v\n";
		if ($v eq "qdr:h"){
			$tbs .= "(Results from the last hour)";
		}
		elsif ($v eq "qdr:d"){
			$tbs .= "(Results from the last 24 hours)";
		}
		elsif ($v eq "qdr:w"){
			$tbs .= "(Results from the last week)" ;
		}
		elsif ($v eq "qdr:m"){
			$tbs .= "(Results from the last month)" ;
		}
		elsif ($v eq "qdr:y"){
			$tbs .= "(Results from the last year)";
		}
		elsif ($v eq "li:1"){
			$tbs .= "(Verbatim results - rather than All results)" 
		}
		elsif ($v eq "sbd:1"){
			$tbs .= "(Sort by Date)";
		}
		elsif ($v =~ m/ctr:country(..)/){
			$tbs .= "(Country: $1)" ;
		}
	}
	
	$tbs =~ s/\)\(/, /g;
	return "$tbs";
}

#show results for a specific country
#could include lookup for each country
# list is probably here: https://developers.google.com/adwords/api/docs/appendix/geotargeting
sub parse_cr($){
	my $cr = shift;
	
	return "$cr\t\tEmpty" if ($cr eq "");
	
	$cr =~ s/Country(..)//g;	
	return	"Country$1 (Country: $1)" ; 
}


#seen values - 
# rja - unsure
sub parse_cad($){
	my $cad = shift;
	return "$cad\t\tseen unsure -- NOT IMPLEMENTED" if ($cad eq "rja");
	return "$cad\t\t-- NOT IMPLEMENTED";
}

# seen value 2 so far
sub parse_espv($){
	my $espv = shift;
	return "$espv\t\t seen -- NOT IMPLEMENTED" if ($espv eq "2");
	return "$espv\t\t -- NOT IMPLEMENTED";
}


# http://www.wordstream.com/blog/ws/2012/02/24/keyword-not-provided-esrc
# above link explains that esrc=s may indicate query withheld.
sub parse_esrc($){
	my $esrc = shift;
	return "$esrc\t\t(May relate to keyword not provided)" if ($esrc eq "s");
	return "$esrc\t\t -- UNKNOWN";
}


# seen values 
# j - unsure
sub parse_rct($){
	my $rct = shift;
	return "$rct\t\tseen-- NOT IMPLEMENTED" if ($rct eq "j");
	return "$rct\t\t-- NOT IMPLEMENTED";
}


# “sa=N”: User searched and “sa=X”: User clicked on related searches in the SERP).
# http://www.t75.org/2012/06/deconstructing-googles-url-search-parameters/
# confirmed the sa=X, this so far has only been seen when saving the link from a related search (or if you open it in a new tab)
# usually when opening a result in a new tab from the SERP you'll see sa=t
# havent seen sa=N yet
sub parse_sa($){
	my $sa = shift;
	return "$sa\t\tUser clicked on related searches in the SERP. Also seen if user clicked on image search after initial search" if ($sa eq "X");
	return "$sa\t\tUser searched (to confirm)" if ($sa eq "N");
	return "$sa\t\tseen but -- NOT IMPLEMENTED" if ($sa eq "t");
	return "$sa\t\tunknown -- NOT IMPLEMENTED";
}

sub parse_uact($){
	my $uact = shift;
	return "$uact\t\t -- NOT IMPLEMENTED";
}

# iniital testing on chrome, logged in, shows ion means instant is turned on. but that doesn't mean it works if the computer/internet connection ? isnt fast enough
sub parse_ion($){
	my $ion = shift;
	return "$ion\t\t -- Inital Testing indicated this means that Instant is on, however Instant may not always function depending on the setting" if ($ion eq "1");
	return "$ion\t\t -- not implemented yet"
}


sub parse_usg($){
	my $usg = shift;
	return "$usg\t\t -- NOT IMPLEMENTED";
}

sub parse_pbx($){
	my $pbx = shift;
	return "$pbx\t\t -- NOT YET IMPLEMENTED"; # if ($pbx eq "1");
}

sub parse_psig($){
	my $psig = shift;
	return "$psig\t\t -- NOT IMPLEMENTED";
}


sub parse_bav($){
	my $bav = shift;
	return "$bav\t\t -- NOT IMPLEMENTED";
}

sub parse_bvm($){
	my $bvm = shift;
	return "$bvm\t\t -- NOT IMPLEMENTED";
}


# https://googlesystem.blogspot.com.au/2006/07/meaning-of-parameters-in-google-query.html
# UNTESTED
sub parse_filter($){
	my $filter = shift;
	
	#unable to recreate so unsure if 1 = hide, or dont hide
	return "$filter\t\t(untested)";
	
	#return "$filter\t\t(hide duplicate results) (untested)" if ($filter eq "1");
	#return "$filter\t\t(don't hide duplicate results) (untested)" if ($filter eq "0");
}

# so far on chrome seen when searching from the google search box in image search but not if you search on google and then change to image search

# seen when searching using the google search box 
# contains information about the users search


# going into search settings and changing "Private results" to show "Do not use private results"
# can't really think how this would be forensically useful
# dpr = 1 on video search even if it's not selected on the settings page
sub parse_dpr($){
	my $dpr = shift;
	return "$dpr\t\t(Do not use private results)" if ($dpr eq "1");
}


# further testing required for characters typed and deleted. so far it looks like val[9] indicates a change in the number of characters
# if searched from the images.google.com it starts with img
sub parse_gs_l($){
	my $gs_l = shift;
	my @vals = split /\./, $gs_l;
	my $comment = "";
	
	$comment .= "(mouse-click on suggestion)" if ($vals[1] eq "1");
	$comment .= "(keyboard [enter] key)" if ($vals[1] eq "3");
	$comment .= "(Google Instant Search)" if ($vals[1] eq "10");
	
	$comment .= "(".ordinal($vals[2]+1). " entry selected)" if ($vals[2]);	
		$comment .= "(Characters changed, more testing required" if ($vals[9]);
    
	#$comment .= "(".$vals[7]." may indicate time it takes to get from getting to google to submitting the search, further testing required)" if ($vals[7]);

	#$comment .= "(May indicate - ".$vals[9]." characters changed" if ($vals[9]);   
    #$comment .= "(May indicate - ".$vals[10]." characters deleted" if ($vals[10]);		
	
	#$comment .= ")";
	$comment =~ s/\)\(/, /g;
	return $gs_l."\t\t". $comment. "-- IN PROGRESS";
}













#https://deedpolloffice.com/blog/articles/decoding-ved-parameter

#Ved parser by https://github.com/beschulz/ved-decoder
# updated - https://github.com/TomAnthony/ved-decoder

# This uses it's own proto library, so may not be the most up to date





sub parse_VED($){
	my $ved = shift;
	my $ved_parser = "python ved-decoder-master/ved.py";
	my $command = "echo $ved | $ved_parser > ved_temp"; 
	system (qq{$command});
	my $comment = readTemp("ved_temp");

	# find ts: parameter
	$comment =~ s/\n//g;
	$comment =~ s/.*ts: (\d*),.*//g;
	
	my $unix = substr($1, 0, 10);
	my $timezone = $timezone_modifier * (60 * 60);
	my $gm_unix = gmtime($unix+$timezone);
	
	if ($timezone_modifier =~ /-/){
		$comment = "($unix UTC = $gm_unix UTC$timezone_modifier)" ;
	}
	else {
		$comment = "($unix UTC = $gm_unix UTC+$timezone_modifier)";
	}
	
	push @alerts, "VED: There are other parameters, the timestamp is the only one I currently extract";
	return "$ved\t\t$comment\n";
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
	my $n = 100;
	my $character = '=';
	my $text =~ s/^(.*)/$character x $n . $1/mge;
	print $text."\n";
}

sub printDivider{
	my $n = 100;
	my $character = '-';
	my $text =~ s/^(.*)/$character x $n . $1/mge;
	print $text."\n";
}

#CPAN module - use Lingua::EN::Numbers::Ordinate;
#http://stackoverflow.com/questions/11369907/how-do-i-retrieve-an-integers-ordinal-suffix-in-perl-like-st-nd-rd-th
sub ordinal {
  return $_.(qw/th st nd rd/)[/(?<!1)([123])$/ ? $1 : 0] for int shift;
}

sub _help {
	print<< "EOT";
GSERPent v.$VERSION - Google URL Parser
GSERPent [-u url] [-f file] [-p param] [-t] [-tz] [-h]
Parses Google Search and Redirect URLs to provide additional data
  -u|url ............Single URL
  -f|file ...........Read a list of URLS
  -p|param ..........Print only supplied parameter
  -t|table ..........Table output
  -tz|timezone ......Timezone modifier (ie +5, -5) -- currently only available for the UST parameter
  -h.................Help
  
Lists: Required format is URL|Comment. The comment will be included in the output
Lines beginning with # are ignored
EOT
}
