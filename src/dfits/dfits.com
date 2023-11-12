# FITS reader common

int	len_record		# Length of FITS records in bytes

# Option flags
bool	long_header		# Print a long header (FITS header cards)
bool	form_header

# Tables
int	nkeywords		# number of keywords (and formats) stored
pointer	key_table[MAX_TABLE]	# keywords
pointer fmt_table[MAX_TABLE]	# formats
char	opt_table[MAX_TABLE]	# format options

common	/dfitscom/ len_record, long_header, form_header,
	nkeywords, key_table, fmt_table, opt_table
