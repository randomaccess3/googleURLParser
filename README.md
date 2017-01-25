# googleURLParser
parser for Google search strings

Install on Windows:
ActiveState Perl
ActiveState Python 2.7
ppm install URI
ppm install Text-ASCIITable

Install on Mac:
cpan Text::ASCIITable

Tools:
GSERPent.pl - Google URL parser - run -h for help and usage instructions
  - perl GSERPent.pl -u "url"

Helper Scripts:
IEF_TSV_to_list.pl - converts IEF's TSV output into a list that can be injested with the -f option in GSERPent. To be merged into main program

get_all_parameters.pl - takes a list of urls and output's the unique parameters

uridecode.pl - just basic uri decode of a url

TO DO:
Update GSERPent to fix url input parsing
Improve parsing of parameters after the #
Merge IEF_TSV_to_list into main program
