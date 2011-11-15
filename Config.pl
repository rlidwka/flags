{
	# connection to database
	mysql => {
		db => 'flags',
		user => 'flags',
		pass => 'sjZFwxtneE49xSHp',
	},

	# telnet receiver settings 
	telnet => {
		port => 12321,
	},

	# submitting to flag checker
	submit => {
		answers => {
			"Not a flag" => 0,
			"Accepted" => 1,
			"Rejected" => 0,

			"Invalid flag" => 0,
			"Unknown flag" => 0,
			"Flag validity expired." => 0,
			"You already submitted this flag." => 0,
			"Congratulations, you scored a point!" => 1,
		},
	},

	#flag_regexp => '(\d+)',
	flag_regexp => '[a-zA-Z0-9]{30}==',
	#flag_regexp => '[a-f0-9]{32}',
	#flag_regexp => '[a-zA-Z0-9]{32,}',
}
