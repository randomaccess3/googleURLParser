# convert time

use Getopt::Long;

my %config;
Getopt::Long::Configure("prefix_pattern=(-|\/)");
GetOptions(\%config,qw(unix|u=s timezone|tz=s help|?|h));

if ($config{unix}){
	my $unix = $config{unix};
	
	if ($config{timezone}){
		print modify_unix_timezone($unix);
	}
	else{
		print "$unix = ".gmtime($unix)."\n";
	}
}

if ($config{help} || !%config) {
	_help();
	exit;
}


sub _help {
	print<< "EOT";
convertTime v.$VERSION
convertTime [-u time] [-h]
Convert timestamps
  -u|unix ...........Unix timestamp
  -tz|timezone ......Timezone modifier (ie +5, -5)
  -h.................Help
EOT
}



#returns a modified unix timestamp
sub modify_unix_timezone($){
		my $unix = shift;
		my $timezone_modifier = $config{timezone};
		my $timezone = $timezone_modifier * (60 * 60);
		my $comment = "";
		my $gm_unix = gmtime($unix+$timezone);
	
		# check to see if its either +12,12,0, -12, throw error if not
	
		if ($timezone_modifier =~ /-/){
			$comment = "$unix UTC = $gm_unix UTC$timezone_modifier" ;
		}
		else {
			$comment = "$unix UTC = $gm_unix UTC+$timezone_modifier";
		}
		return $comment;
}