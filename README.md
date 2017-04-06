# googleURLParser - GSERPent

Parser for Google search strings

This tool came about to try and identify the data located within a Google URL.
Using this script examiners may be able to understand a little bit more about how the user came to a certain page, or what their actions were. 

Usage Example:

perl GSERPent.pl -u "http://www.google.com"


Requires -  Perl, and Python

Perl Libraries Required
Windows
            ppm install URI
            ppm install Text-ASCIITable

Mac
            cpan Text::ASCIITable

Helper Scripts:
* IEF_Google_Searches_TSV_to_list.pl - converts IEF's TSV output from the Google Searches section into a list that can be injested with the -f option in GSERPent.

* get_all_parameters.pl - given a list of Google URLs, provide a list of all of the parameters

* parameter_values.pl - given a list of Google URLs, provide a list of all of the parameters, and the grouped values

* testGSERPent.pl - run test cases, not really populated

* uridecode.pl - split URLs by & and # value

* convertTime.pl - command line unix timestamp converter


Known Issues: 
* Doesn't parse the data in the fragment (after the #)
