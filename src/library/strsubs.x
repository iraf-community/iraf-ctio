# STRSUBS - Extract a substring from a string in a given string range.
# The limits in the input string are given by the first and last
# character positions in the string.
# If both limits are out of the input string limits, no extraction
# is performed.
# If the first position is geater than the last one, then an inverse 
# extraction is perfoemed, i.e., the output string is reflected.
# Character positions may be truncated if an extraction beyond the limits
# of the input string is intended, and/or if there is no more room in
# the output string.
# The number of characters extracted is returned as the procedure value.

int procedure strsubs (instr, firstp, lastp, outstr, maxch)

char	instr[ARB]		# input string
int	firstp, lastp		# substring range
char	outstr[ARB]		# output string
int	maxch			# max. number of characters

bool	forward
int	i, first, last, len
int	strlen()

begin
	# No characters in output string
	if (maxch == 0) {
	    outstr[1] = EOS
	    return (0)
	}

	# Length of input string
	len = strlen (instr)

	# If both limits are out from the input string limits,
	# no extraction is performed, and a null string is returned
	# in the output string.
	if ((firstp < 1 && lastp < 1) || (firstp > len && lastp > len)) {
	    outstr[1] = EOS
	    return (0)
	}

	# Set the extraction direction
	if (firstp < lastp)
	    forward = true
	else
	    forward = false

	# Limit extraction positions, so only existing characters
	# will be extracted from the input string.
	first = max (1, min (firstp, len))
	last = max (1, min (lastp, len))

	# Copy characters from input string into output string,
	# taking into account the maximum number of characters
	# in the output string.
	if (forward) {
	    last = min (last, first + maxch - 1)

	    do i = first, last
		outstr[i-first+1] = instr[i]

	    outstr[last-first+2] = EOS
	} else {
	    last = max (last, first - maxch + 1)

	    do i = first, last, -1
		outstr[first-i+1] = instr[i]

	    outstr[first-last+2] = EOS
	}

	# Return number of characters extracted
	return (abs (last - first + 1))
end
