# STRREP - Replace all ocurrences of a given string by another string.

procedure strrep (str, find, replace, outstr, maxch)

char	str[ARB]
char	find[ARB]
char	replace[ARB]
char	outstr[ARB]
int	maxch

bool	match
int	i, ip, op
int	len, flen, rlen

int	strlen()

begin
	# Initialize
	len = strlen (str)
	flen = strlen (find)
	rlen = strlen (replace)
	ip = 1
	op = 1

	# Loop
	while (ip <= len && op <= maxch) {

	    # Find starting point to replace
	    if (str[ip] == find[1]) {

		# Check if there is a perfect match
		match = true
		do i = 2, flen {
		    if (str[ip + i - 1] != find[i]) {
			match = false
			break
		    }
		}

		# Copy replace string into output string, and
		# adjust the input string pointer to the next
		# character not belonging to the find string.
		if (match) {
		    for (i = 1; i <= rlen && op <= maxch; i = i + 1) {
			outstr[op] = replace[i]
			op = op + 1
		    }
		    ip = ip + flen
		}
	    }

	    # Copy and count characters
	    outstr[op] = str[ip]
	    ip = ip + 1
	    op = op + 1
	}

	# Mark end of string
	outstr[op] = EOS
end
