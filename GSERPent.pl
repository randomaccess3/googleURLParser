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
# 20170227  - minor updates
#			- add authuser parameter, update site
# 20170228	- move timezone parsing code to routine and started adding option to parse timezone for certain artefacts
#			- added output to history file if -hist option provided
# 20170306	- added additional source, SEI parameter (untested), chips parameter, spell parameter, nfpr, added alert for ved
#			- updated psi
# 20170313	- fix up timezone_modifier code
# 20170314	- fixed timezone_modifier code again, and removed 'not implemented' comments of routines
#			- removed unnecessary prints when param argument is entered
# 20170403  - various updates to alerts, add initial wrapper for wrapid
# 20170404  - fix gfe_rd, update alert for redirect, update to source, update to ust alert
# 20170410  - fix sourceid output, fix framgent formatting, rls parameter & alerts
# 20170413  - update alert for fragment
# 20170501  - update ust alert and gs_l parameter
# 20170507  - continued updating gs_l parameter
# 20170509  - fixed table output and updated help, updated gs_l typing times, added OI parameter
# 20171106  - added RLZ parameter (see notes above routine), fixed cr parameter bug, 
# 20190909  - added sxsrf parsing routine and change datetime presentation

my $VERSION = "20190909";

#To Install Windows
# ppm install URI (which I think comes with perl now)
# ppm install Text-ASCIITable
# requires python 2.7 installed to run the EI parser - https://raw.githubusercontent.com/cheeky4n6monkey/4n6-scripts/master/google-ei-time.py
# Requires cheeky4n6monkey/4n6-scripts/master/google-ei-time to be in the same folder
# Requires https://github.com/TomAnthony/ved-decoder/ which is an updated forked parser originally written by Benjamin Schulz (https://github.com/beschulz) to be extracted into the same directory (ved-decoder-master)
# pip install protobuf to use the ved-decoder (although there is a version of protobuf included so might not be required to install)
# pip install six

#To Install OS X
# cpan Text::ASCIITable

# Known bug
# Doesnt deal with parameters in fragment
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
use POSIX qw(strftime);
use Getopt::Long;
use File::Spec;

use Text::ASCIITable;



my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config,qw(url|u=s file|f=s param|p=s table|t:s timezone|tz=s history|hist help|?|h));


our @alerts = ();
#our %parameters = {};

if ($config{help} || !%config) {
	_help();
	exit;
}

my $url; 
if ($config{url}) {
	$url = $config{url};
	
	if ($config{history}){
		open(FH,">>","history.txt");
		print FH $url."|".localtime()."\n";
		close(FH);
	}
	
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
		
		if ($config{param}){
			my $p = $config{param};
			if ($url =~ m/$p/){
				# do nothing
			}
			else{
				next;
			}
		}
		
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
	my $url = shift;
	
	my $u = URI->new($url);
	my ($scheme, $domain, $path, $query, $frag) = uri_split($u);
	$frag =~ s/\&/\n\t\t/;
	# load parameters (split by &)
	my %parameters = $u->query_form($u);

	# ALERTS
	
	push @alerts, "/URL: FF/Chrome/Safari - Redirect link, usually indicating opening in new tab/window. Query will most often be blank.\n/URL: On IE/Edge this appears from clicking a link, rather than opening a new tab" if ($path eq "/url");
	push @alerts, "/IMGRES: Imgres shows up if you right click on a picture in image search and save the url. The URL doesn't always appear in the task bar or internet history" if ($path eq "/imgres");
	push @alerts, "URL taken from cache - haven't tested the parsing" if ($path eq "/gen_204" || $path eq "/complete/search");	
	
	
	# If a fragment (hash) exists in the URL then the previous search was before the hash and the current search was in the q after the hash
	# Sometimes google won't add the #, and just recreates the query again
	push @alerts, "Fragment can sometimes indicate a second search - parameter parsing not currently implemented, however fragment displayed below.\nFragment = \n\t\t$frag" if ($frag);

	#If the q and oq exist and arent equal
	if (exists($parameters{"q"}) && (exists($parameters{"oq"})) && ($parameters{"q"} ne $parameters{"oq"})){
		push @alerts, "Regarding the q and oq parameters: Either additional search, or suggested search was selected from search bar (tested on chrome)";
	} 
	
	# UST parameter appears to relate to when Gmail was opened if it's in a redirect link from gmail	
	if (exists($parameters{"ust"})){
		push @alerts, "UST: In testing I have found the UST timestamp to be a Google-server timestamp indicating 24 hours after Gmail was opened." if ($parameters{"source"} eq "gmail");
		push @alerts, "UST: In testing I have found the UST timestamp to be a Google-server timestamp indicating 24 hours after the image search was conducted." if ($parameters{"source"} eq "images");
	}
	
	if (exists($parameters{"EI"})){
		push @alerts, "EI: Set by Google's Time Servers to indicate the start of a session. If found in cache this isn't always reliable";
	}
	
	if (exists($parameters{"SEI"})){
		push @alerts, "SEI: untested";
	}
	
	if (exists($parameters{"ved"}) && exists($parameters{"spell"})){
		push @alerts, "VED: If time is present this may indicate the time that the user selected the correct spelling of the searched term";
	}
	
	
	# rls in IE only appears when you search from the address bar. and gs_l only appears when you search from the google search bar.
	# As a result if the rls parameter is in the URL it means that the user most likely searched from the address bar, and then modified the search
	# in the google results search box
	if (exists($parameters{"rls"}) && exists($parameters{"gs_l"})){
		push @alerts, "Most likely a secondary search";
	}
	
	if (exists($parameters{"gs_l"})){
		push @alerts, "GS_L: User searched using search bar";
	}
	
	# PARSE PARAMETERS
	
	foreach my $u (sort keys %parameters){
		
		#Unsure why the hash has a HASH -> undef entry in it, this line skips it
		next if (!defined($parameters{$u}));
		
		# If -p option used then skip if the current parameter doesn't match provided parameter
		next if ($config{param} && $config{param} ne $u);
		 
		# Sends the parameter value to the subroutine for parsing
		# result is returned and printed on a new line with the parameter name
		$parameters{$u} = parse_EI($parameters{$u}) if ($u eq "ei");
		$parameters{$u} = parse_SEI($parameters{$u}) if ($u eq "sei");
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
		$parameters{$u} = parse_chips($parameters{$u}) if ($u eq "chips");
		$parameters{$u} = parse_authuser($parameters{$u}) if ($u eq "authuser");
		$parameters{$u} = parse_spell($parameters{$u}) if ($u eq "spell");
		$parameters{$u} = parse_wrapid($parameters{$u}) if ($u eq "wrapid");
		$parameters{$u} = parse_nfpr($parameters{$u}) if ($u eq "nfpr");
		$parameters{$u} = parse_rls($parameters{$u}) if ($u eq "rls");
		$parameters{$u} = parse_oi($parameters{$u}) if ($u eq "oi");
        $parameters{$u} = parse_sxsrf($parameters{$u}) if ($u eq "sxsrf");
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
		
		print "$u=$parameters{$u}\n" if (!(defined $config{table}));
		
	}
		
	my $value_colwidth = 40;
	my $comment_colwidth = 50;
	
	# Table has an optional width value for the comment column, if none provided then the width is set to 50
	if (defined $config{table}){
	
		$comment_colwidth = $config{table} if ($config{table});
	
		my $t = Text::ASCIITable->new();
		$t->setCols('Parameter','Value','Comment');
		$t->alignCol('Parameter','left');
		$t->alignCol('Value','left');
		$t->alignCol('Comment','left');
		
		
		$t->setColWidth('Value', $value_colwidth,1);
		$t->setColWidth('Comment', $comment_colwidth,1);
		
		#load new hash and move the key from name, value+comment, to name+value, comment
		my $param_name;
		foreach $param_name (sort keys %parameters){
			next if (!defined($parameters{$param_name}));	
			$parameters{$param_name} =~ s/\t\t/\t/g; #replace the double tab with a single tab
			my ($param_value, $param_comment) = split /\t/, $parameters{$param_name}; #split the parameter value with the comment
			
			$param_value = wrap($param_value, $value_colwidth); #wrap is required so that the data isn't cut off
			$param_comment = wrap($param_comment, $comment_colwidth);
			
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


# Currently unsure what this timestamp means
# This is seen from September 2019 (unsure where it first begun)
# Only when going to google, clicking the search box and searching with Chrome. Untested for other browsers.
# Possibly region based.
sub parse_sxsrf($){
    my $sxsrf = shift;    
    my @params = split /\:/, $sxsrf;
    my $first = $params[0];
    my $second = $params[1]/1000;
    my $unix = modify_unix_timezone($second);
    my $comment = $unix;
        
    return "$sxsrf\t\t($comment)";
}


# found when examining the cache files. so far seen on chrome havent tested anything else
# it seems that the two timestamps are different but not sure why
# may relate to multiple searches in the same session
# if PSI doesn't have 3 parameters then it won't parse properly
sub parse_PSI($){
	my $psi = shift;
	
	my @params = split /\./, $psi;
	if (@params != 3){
		return "$psi\t\t(Unknown PSI)";
	}
	
	my ($ei, $unix, $unknown) = split /\./, $psi;
	
	
	my $command = "python google-ei-time.py -e \"".$ei."\" > temp";
	my $unix = run_single_line_command($command, "temp");
	
	$unix =~ s/\n//g;
	$unix =~ s/.*Extracted timestamp = //g;
	$unix =~ s/(0-9)*Human.*//g;
	my $ei = modify_unix_timezone($unix);
	
	#$unix last three digits removed to make it a unix timestamp. Should match the EI timestamp
	#$unix = substr($unix, 0, 10);
	$unix = modify_unix_timezone($unix);
	
	my $comment = "$ei,$unix,$unknown";
	return "$psi\t\t($comment)";
}

# Contains a timestamp, unsure what it means, or how to generate it
sub parse_wrapid($){
	my $wrapid = shift;
	my $comment = "Unsure what this means, contains unix timestamp";
	return "$wrapid\t\t($comment)";
}


#indicates the start of a session
#can reliably get this value if you go to Google's homepage on chrome, and when a new tab/window is opened on a navigation number at the bottom of a search
sub parse_EI($){
	my $ei = shift;	
	#my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";

	my $command = "python google-ei-time.py -e \"".$ei."\" > temp";
	my $unix = run_single_line_command($command, "temp");
	
	$unix =~ s/\n//g;
	$unix =~ s/.*Extracted timestamp = //g;
	$unix =~ s/(0-9)*Human.*//g;
	my $comment = modify_unix_timezone($unix);
	
	return "$ei\t\t($comment)";
}


# unsure what this parameter means
sub parse_SEI($){
	my $sei = shift;	
	#my $command = "python google-ei-time.py -q -e \"".$ei."\" > temp";

	my $command = "python google-ei-time.py -e \"".$sei."\" > temp";
	my $unix = run_single_line_command($command, "temp");
	
	$unix =~ s/\n//g;
	$unix =~ s/.*Extracted timestamp = //g;
	$unix =~ s/(0-9)*Human.*//g;
	my $comment = modify_unix_timezone($unix);
	
	return "$sei\t\t($comment)";
}




sub parse_GFE_RD($){
	my $gfe_rd = shift;
	return "$gfe_rd\t\t(Country Redirect - Redirect to your country's Google homepage)" if ($gfe_rd eq "cr");
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

#occasionally shows up on the Google Home page (instead of sig2)
sub parse_authuser($){
	my $authuser = shift;
	if ($authuser eq "0"){
		return "$authuser\t\t(A user was logged in)";
	}
	else {
		return "$authuser\t\t(Unsure, haven't seen before)";
	}
	
}

sub parse_sourceid($){
	my $sourceid = shift;
	my $comment = "";
	$comment = "(Google Chrome)" if ($sourceid eq "chrome");
	$comment = "(Google Chrome - Instant Enabled)" if ($sourceid eq "chrome-instant");
	$comment = "(Google Chrome - Instant Enabled? unsure)" if ($sourceid eq "chrome-psyapi2");
	$comment = "(Google Chrome Mobile)" if ($sourceid eq "chrome-mobile");
	$comment = "(Opera)" if ($sourceid eq "opera");
	if ($sourceid eq "ie7" || $sourceid eq "ie8"){
		push @alerts, "SOURCEID: Not indicative of version of IE";
		# The following reference is listed in HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\SearchScopes\{97312F68-F26E-45DA-B0D9-E02A27222048}
		# URL = https://www.google.com/search?q={searchTerms}&sourceid=ie7&rls=com.microsoft:{language}:{referrer:source}&ie={inputEncoding?}&oe={outputEncoding?}
		# As shown ie7 is hardcoded as part of the addon.
		# Similarly urls found in cache would indicate ie8 
		# SuggestionsURL = https://www.google.com/complete/search?q={searchTerms}&client=ie8&mw={ie:maxWidth}&sh={ie:sectionHeight}&rh={ie:rowHeight}&inputencoding={inputEncoding}&outputencoding={outputEncoding}
		
		$comment = "(Internet Explorer)";
	}
	
	return "$sourceid\t\t$comment";
}

#identified firefox-a on https://googlesystem.blogspot.com.au/2006/07/meaning-of-parameters-in-google-query.html, but haven't researched it yet

sub parse_client($){
	my $client = shift;
	my $comment = "";
	$comment = "(Mozilla Firefox)" if ($client eq "firefox-a");
	$comment = "(Mozilla Firefox)" if ($client eq "firefox-b");
	$comment = "(Mozilla Firefox - Search using Address Bar)" if ($client eq "firefox-b-ab");
	$comment = "(Chrome for Android)" if ($client eq "ms-android-google");
	$comment = "(Opera)" if ($client eq "opera");
	$comment = "(Safari)" if ($client eq "safari");
	return "$client\t\t$comment";
}

# unsure what it means but so far have only seen the value to be psy-ab
sub parse_sclient($){
	my $sclient = shift;
	my $comment = "";
	$comment = "(Seen in cache across a number of browsers)" if ($sclient eq "psy-ab");
	return "$sclient\t\t$comment";
}

# seen chrome, blank when search from google homepage
sub parse_site($){
	my $site = shift;
	my $comment = "";
	#return "$site\t\tunknown" if ($site eq "");
	$comment = "(Previous page was Web Homepage)" if ($site eq "webhp");
	return "$site\t\t$comment";
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
		#my $q = $parameters{"q"};
		$comment .= "(User right clicked on the word found in the 'q' parameter and selected \"Search Google for 'q parameter'\" from the context menu in a Chromium-based browser)";
	}
	
	
	if (exists $args[3]){
		(my $time, my @other) = split /j/, $args[3];
		$comment .= "($time milliseconds from first keypress to search. Other parameters unknown)";
	}
	
	$comment =~ s/\)\(/, /g;
	
	return "$aqs\t\t$comment";
}

#http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.258.9190&rep=rep1&type=pdf - Chrome RLZ and Unknown Features
# "The RLZ information includes a non-unique promotional tag that contains information about how Chrome was obtained, the week when Chrome was installed, and the week when the first search was performed"
# https://blog.chromium.org/2010/06/in-open-for-rlz.html
sub parse_rlz($){
	my $rlz = shift;
	return $rlz."\t\(see source: language and country settings)";
}

sub parse_rls($){
	my $rls = shift;
	my $comment = "";
	$comment = "(Search from Address Bar)" if ($rls eq "com.microsoft:en-AU:IE-Address");
	$comment = "(Google Search Suggestion selected from Address Bar)" if ($rls eq "com.microsoft:en-AU:IE-SearchBox");
	return $rls."\t\t$comment";
}

sub parse_oi($){
	my $oi = shift;
	my $comment = "";
	if ($oi eq "ddle"){
		$comment = "(Google Doodle Selected)"; 
		push @alerts, "OI: User didn't type the search term but instead the Google Doodle was selected";
	}
	return $oi."\t\t$comment";
}


# Search engine type
sub parse_tbm($){
	my $tbm = shift;
	return "$tbm\t\t(Image Search}" if ($tbm eq "isch");
	return "$tbm\t\t(Video Search}" if ($tbm eq "vid");
	return "$tbm\t\t(News Search}" if ($tbm eq "nws");
	return "$tbm\t\t(Books Search}" if ($tbm eq "books");
	return "$tbm\t\t(Shopping Search}" if ($tbm eq "shop");
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
	my $comment = "(".modify_unix_timezone($unix).")";
	return "$ust\t\t$comment";
}


#only seen in cache - google.com/gen_204?
sub parse_zx($){
	my $zx = shift;
 #first 10 characters are a unix timestamp
	my $unix = substr($zx, 0, 10);
	my $comment = "(".modify_unix_timezone($unix).")";
	push @alerts, "ZX: Unsure of the meaning of this timestamp. Currently only seen in cache";
	return "$zx\t\t$comment";
}


# so far have only seen source = web - havent tested on mobile
# seen gmail when clicking a youtube subscription link from gmail
# seen images when clicking on a "visit page" link in image search
# did a search and changed the returned results from date A to date B, saw source=lnt
# sometimes I see source=hp not sure why, may indicate the user searched from the homepage
sub parse_source($){
	my $source = shift;
	my $comment = "";
	$comment = "(Web - standard browser search)" if ($source eq "web");
	$comment = "(Clicked on link from Gmail)" if ($source eq "gmail");
	$comment = "(Clicked link from Image Search)" if ($source eq "images");
	$comment = "(Clicked link from Video Search)" if ($source eq "video");
	$comment = "(seen - Unknown)" if ($source eq "lnt");
	$comment = "(Click on Google Search through chrome://apps)" if ($source eq "search_app");
	$comment = "(Home Page)" if ($source eq "hp"); #may indicate the user searched from the homepage ie images.google.com
	$comment = "(User selected redirect from other Google page -- needs confirmation)" if ($source eq "lnms"); # may indicate user went from one google search type to another ie search-->images	
	return "$source\t\t$comment";
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


# seen in image search as a results filter
# filters are presented as a row of boxes under the search bar
# so far only seen when user accesses images.google.com directly rather than when redirected to images.google.com
# only allows two filters
sub parse_chips($){
	my $chips = shift;
	my $comment = "";
	my @filters = split /,/, $chips;
	
	if (@filters == 2){
		$filters[0] =~ s/q://g;
		$filters[1] =~ s/g_1://g;
		$comment = "(Initial query for '$filters[0]', then filtered by '$filters[1]')";
	}
	
	if (@filters == 3){
		$filters[0] =~ s/q://g;
		$filters[1] =~ s/g_1://g;
		$filters[2] =~ s/g_1://g;	
		$comment = "(Initial query for '$filters[0]', then filtered by '$filters[1]', and then '$filters[2]')";
	}
	
	return "$chips\t\t$comment";
}

# seen - 1
sub parse_spell($){
	my $spell = shift;
	my $comment = "";
	if ($spell eq "1"){
		$comment = "User selected to correct spelling of search result";
	}
	else{
		$comment = "unknown";
	}
	return "$spell\t\t($comment)";
}

# If I search for a term with incorrect spelling, google will provide the search results for the correct spelling
# if I select to search for the incorrect spelling (which is under the search box), then nfpr will appear in the URL
sub parse_nfpr($){
	my $nfpr = shift;
	my $comment = "";
	$comment = "(search term spelled incorrectly, then \"Search instead for <provided search term>\" selected)" if ($nfpr eq "1");
	return "$nfpr\t\t$comment";
}


#show results for a specific country
#could include lookup for each country
# list is probably here: https://developers.google.com/adwords/api/docs/appendix/geotargeting
sub parse_cr($){
	my $cr = shift;
	return "$cr\t\t(Empty)" if ($cr eq "");
	
	$cr =~ s/country(..)//g;
	return	"Country$1\t\t(Country: $1)" ; 
}


#seen values - 
# rja - unsure
sub parse_cad($){
	my $cad = shift;
	my $comment = "";
	$comment = "" if ($cad eq "rja");
	return "$cad\t\t$comment";
}

# seen value 2 so far
sub parse_espv($){
	my $espv = shift;
	my $comment = "";
	return "$espv\t\t(unknown)" if ($espv eq "2");
	return "$espv\t\t$comment";
}


# http://www.wordstream.com/blog/ws/2012/02/24/keyword-not-provided-esrc
# above link explains that esrc=s may indicate query withheld.
sub parse_esrc($){
	my $esrc = shift;
	return "$esrc\t\t(May relate to keyword not provided)" if ($esrc eq "s");
	return "$esrc\t\t -- UNKNOWN";
}


# Only seen the value "j" unsure what it means
sub parse_rct($){
	my $rct = shift;
	my $comment = ""; 
	$comment = "(Only ever seen the value j - unsure what it means)" if ($rct eq "j");
	return "$rct\t\t$comment";
}


# “sa=N”: User searched and “sa=X”: User clicked on related searches in the SERP).
# http://www.t75.org/2012/06/deconstructing-googles-url-search-parameters/
# sa=x appears if the user clicks on the links in the "Search related to <search term>"
# If a user goes to images.google.com directly and then filters the results then sa=x
# usually when opening a result in a new tab from the SERP you'll see sa=t
# sa=N is seen when the user clicks on the next page

# Possible options include: t, X, 1, N, i


sub parse_sa($){
	my $sa = shift;
	my $comment = "";
	$comment = "(User clicked on related searches in the SERP. Also seen if user clicked on images after initial search. Or filter selected from images.google.com)" if ($sa eq "X");
	$comment = "(Selected next page)" if ($sa eq "N");
	$comment = "(Seen in redirect from image search)" if ($sa eq "i");
	
	#$comment = "(unknown)" if ($sa eq "t");
	return "$sa\t\t$comment";
	
}

sub parse_uact($){
	my $uact = shift;
	my $comment = "";
	return "$uact\t\t$comment";
}

# iniital testing on chrome, logged in, shows ion means instant is turned on. but that doesn't mean it works if the computer/internet connection ? isnt fast enough
sub parse_ion($){
	my $ion = shift;
	my $comment = "";
	
	if ($ion eq "1"){
		$comment = "(Instant On)";
		push @alerts, "ION: Inital Testing indicated this means that Instant is on, however Instant may not always function depending on the setting";
	}
	return "$ion\t\t$comment";
}


sub parse_usg($){
	my $usg = shift;
	my $comment = "(Hash of referred URL)";
	return "$usg\t\t$comment";
}

sub parse_pbx($){
	my $pbx = shift;
	my $comment = "";
	return "$pbx\t\t$comment";
}

sub parse_psig($){
	my $psig = shift;
	my $comment = "";
	return "$psig\t\t$comment";
}


sub parse_bav($){
	my $bav = shift;
	my $comment = "";
	return "$bav\t\t$comment";
}

sub parse_bvm($){
	my $bvm = shift;
	my $comment = "";
	return "$bvm\t\t$comment";
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

# Parameter 0 - where the searcher came from: image search, home page, SERP
# Parameter 1 - how they selected the search query from the dropdown list. If no value exists they did not select the value from the dropdown list.
# Parameter 2 - which entry on the list was selected
# Parameter 4 - Time in milliseconds between the current SERP and the new search commencing - time before search box selected
# Parameter 5 - Time in milliseconds between the current SERP and the new search being selected. - time before user stopped typing search
# Parameter 7 - Time in milliseconds between the current and previous SERP being loaded - total time on page
# Parameter 8 - Characters pressed (excluding enter, but including backspace/delete), except on the homepage in Chrome, which is +1 for some reason
# Parameter 26 - whether the user typed the query, or a suggestion was selected without the user typing

sub parse_gs_l($){
	my $gs_l = shift;
	my @vals = split /\./, $gs_l;
	my $comment = "";
	
	my %param_0 = (
		"hp"  => "Home Page",
		"serp" => "Search Engine Results Page",
		"img"  => "Image Search",
	);
	
	# How the user selected the search term
	my %param_1 = (
		"1" => "mouse-click on suggestion",
		"3" => "keyboard [enter] key",
		"10" => "Google Instant Search (untested)",
	);
	
	
	#Paramater 0
	#if the value ($val[0]) exists in the hash of values for param_0 then add it's explanation to the comment
	$comment .= "($param_0{$vals[0]})" if exists ($param_0{$vals[0]});  

	#Paramater 1
	if (exists ($param_1{$vals[1]})){
		$comment .= "($param_1{$vals[1]})";
	}
	else{
		$comment .= "(Query not selected from suggestions)";
	}
	
	#Paramater 2
	$comment .= "(Item ".($vals[2]+1)." on list selected)" if ($vals[2]);
	
	#Paramater 4
	if ($vals[4]){
		if ($vals[4] eq 0){
			$comment .= "(Suggestion clicked on)";
		}
		else{
			$comment .= "(".$vals[4]." milliseconds before selecting search box)";
		}
	}
	
	#Parameter 5
	if ($vals[5]){
		if ($vals[5] eq 0){
			$comment .= "(Suggestion clicked on)";
		}
		else{
			my $time_typing = $vals[5]-$vals[4];
			$comment .= "(".$vals[5]." milliseconds on page before completed typing. ".$time_typing." milliseconds typing query)";
		}
	}
	
	#Parameter 7
	if ($vals[7] ne ""){
		$comment .= "(". $vals[7]." milliseconds on page in total)";
	}
	
	#Parameter 8
	if ($vals[8] ne ""){
		if ($vals[8] eq 0){
			$comment .= "(No characters typed)";
		}
		else {
			if ($vals[0] eq "hp"){
				$comment .= "(".$vals[8]. " keys pressed | In Chrome this is +1)";
			}
			else {
				$comment .= "(".$vals[8]." keys pressed)";
			}
		}
	}
	
	#Parameter 26
	if ($vals[26]){
		if ($vals[26] eq "1"){
			$comment .= "(User typed)";
		}
		elsif ($vals[26] eq ""){
			$comment .= "(Suggestion was selected without the user typing)";
		}
	}
    

	$comment =~ s/\)\(/, /g;
	return $gs_l."\t\t". $comment;
}


#https://deedpolloffice.com/blog/articles/decoding-ved-parameter

#Ved parser by https://github.com/beschulz/ved-decoder
# updated - https://github.com/TomAnthony/ved-decoder

# This uses it's own proto library, so may not be the most up to date

sub parse_VED($){
	my $ved = shift;
	my $ved_parser = "python ved-decoder-master/ved.py";

	my $command = "echo $ved | $ved_parser > ved_temp"; 
	my $comment = run_single_line_command($command, "ved_temp");

	# find ts: parameter and remove extraneous information provided by the ved-decoder-master script
	$comment =~ s/\n//g;
	$comment =~ s/---//g;
	$comment =~ s/$ved//g;
	$comment =~ s/^\{/\(/g;
	$comment =~ s/\}$/\)/g;
	
	if ($comment =~ m/.*ts: (\d*).*/){
	 	my $unix = substr($1, 0, 10);
		$comment = "(".modify_unix_timezone($unix).")";
		push @alerts, "VED: Only timestamp extracted. For other paramaters run ved.py. Unsure what timestamp means, sometimes it's accurate, sometimes it isn't";
	}
return "$ved\t\t$comment\n";
}


# Runs a provided command, and then reads the resultant temp file
sub run_single_line_command($){
	my $command = shift;
	my $temp = shift;
	system (qq{$command});
	my $comment = readTemp($temp);
	$command = "del $temp";
	system (qq{$command});
	return $comment;
}

#returns a modified unix timestamp
sub modify_unix_timezone($){
		my $unix = shift;
		my $timezone_modifier = 0;
		if ($config{timezone}){
			$timezone_modifier = $config{timezone};
			$timezone_modifier =~ s/\+//;	#remove the + if the user includes it, there's no other validation
		}
		my $timezone = $timezone_modifier * (60 * 60);
		my $comment = "";
		#my $gm_unix = gmtime($unix+$timezone);
        
        my $gm_unix = strftime "%Y-%m-%d %H-%M-%S", gmtime($unix+$timezone);
	
		# check to see if its either +12,12,0, -12, throw error if not
	
		if ($timezone_modifier =~ /-/){
			$comment = "$unix UTC = $gm_unix UTC$timezone_modifier" ;
		}
		else {
			$comment = "$unix UTC = $gm_unix UTC+$timezone_modifier";
		}
		return $comment;
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

# wrap(string, width);
# couldn't get asciitable's wrap function to work
# this isn't great, but it seems to work
sub wrap($$){
	my $text = shift;
	my $width = shift;
	$text =~ s/(.{1,$width})/$1\n/gs;
	return $text;
}


#CPAN module - use Lingua::EN::Numbers::Ordinate;
#http://stackoverflow.com/questions/11369907/how-do-i-retrieve-an-integers-ordinal-suffix-in-perl-like-st-nd-rd-th
sub ordinal {
  return $_.(qw/th st nd rd/)[/(?<!1)([123])$/ ? $1 : 0] for int shift;
}

sub _help {
	print<< "EOT";
GSERPent v.$VERSION - Google URL Parser

Parses Google Search and Redirect URLs to provide additional data

Usage: GSERPent [-u url] [-f file] [-p param] [-t [comment column width]] [-tz] [-h]

  -u|url ............Single URL
  -f|file ...........Read a list of URLS
  -p|param ..........Print only supplied parameter
  -t|table ..........Table output, as well as optional column width for the Comment column
  -hist|history .....Store executed URLs in history.txt
  -tz|timezone ......Timezone modifier (ie +5, -5)
  -h.................Help
  
Lists: Required format is URL|Comment. The comment will be included in the output
Lines beginning with # are ignored
EOT
}
