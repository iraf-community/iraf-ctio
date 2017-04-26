# STRINS - Insert a string into another string, at a reference string.
#
# Finds the first ocurrence of the reference string in the input string
# and inserts the new string just before. If the reference string is not
# found, the new string is concatenated to the input string. A null
# reference string is equivalent to an insertion before the first character.
# If there isn't enough space in the output string, the last characters
# may be lost.

procedure strins (instr, refstr, newstr, after, outstr, maxch)

char	instr[ARB]		# input string
char	refstr[ARB]		# reference string
char	newstr[ARB]		# string to insert
int	after			# insert after the reference string ?
char	outstr[ARB]		# output string
int	maxch			# max. number of characters

int	i, i1, i2, pos, newlen
int	strsearch(), strlen()

begin
	# Find the insertion point
	pos = strsearch (instr, refstr)

	# Insert the string if the reference string is
	# present, or just concatenate strings if not
	if (pos == 0) {
	    call strcpy (instr, outstr, maxch)
	    call strcat (newstr, outstr, maxch)
	} else {

	    # Adjust insertion point
	    if (after == NO)
	        pos = pos - strlen (refstr)

	    # Copy first (common) part
	    call strcpy (instr, outstr, min (pos-1, maxch))
	    
	    # Evaluate new string length
	    newlen = strlen (newstr)

	    # Copy new string
	    i1 = pos
	    i2 = min (pos + newlen - 1, maxch)
	    do i = i1, i2
		outstr[i] = newstr[i-pos+1]
	  
	    # Copy last (shifted) part
	    i1 = pos + newlen
	    i2 = min (newlen + strlen (instr), maxch)
	    do i = i1, i2
		outstr[i] = instr[i-newlen]

	    # Put EOS
	    outstr[i2+1] = EOS
	}
end
