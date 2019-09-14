# googleURLParser - GSERPent

### Parser for Google search strings

This tool came about to try and identify the data located within a Google URL.
Using this script examiners may be able to understand a little bit more about how the user came to a certain page, or what their actions were. 
You can view the webcast (and download the slides) for the presentation I did on 11th May 2017 here: https://www.sans.org/webcasts/wwwgooglecom-searchqwhat-plus-does-plus-this-plus-all-plus-mean-104857
Requires -  Perl, and Python

## Usage Example:

* perl GSERPent.pl -u "http://www.google.com"
* perl GSERPent.pl -f input.txt

List input formatting expects [link] | [comment] and ignores lines starting with #

## Perl Libraries Required
Windows
- ppm install URI
- ppm install Text-ASCIITable

Mac
- cpan Text::ASCIITable

Linux (debian)
- sudo apt install build-essentials
- sudo cpan Text::ASCIITable

### Helper Scripts:
* IEF_Google_Searches_TSV_to_list.pl - converts IEF's TSV output from the Google Searches section into a list that can be injested with the -f option in GSERPent.

* get_all_parameters.pl - given a list of Google URLs, provide a list of all of the parameters

* parameter_values.pl - given a list of Google URLs, provide a list of all of the parameters, and the grouped values

* testGSERPent.pl - run test cases, not really populated

* uridecode.pl - split URLs by & and # value

* convertTime.pl - command line unix timestamp converter


### Known Issues: 
* Doesn't parse the data in the fragment (after the #)

### Credits
It's in the code but I realised I didn't link to the original modules that I've included in this repo for ease of use
1. Cheeky4n6Monkey for Google-Ei-time - https://raw.githubusercontent.com/cheeky4n6monkey/4n6-scripts/master/google-ei-time.py
2. Tom Anthony and Benjamin Schulz (https://github.com/TomAnthony/ved-decoder/ which is an updated fork of the code by https://github.com/beschulz)
