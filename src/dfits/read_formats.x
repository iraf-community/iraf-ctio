include	<ctype.h>
include	"dfits.h"

# READ_FORMATS - Read keywords and formats from a file. The keyword and
# the format are extracted from the lines red from the file and are stored
# in the stack. The pointers to the keywords and formats are stored in two
# array in the common block (dfits.com).
# The format strings are converted into FMTIO output format specification
# as they are written into the table.

procedure read_formats (name)

char	name[ARB]	# file name of format file

int	fd, ip, keylen, fmtlen
char	line[SZ_LINE], keyword[SZ_LINE], format[SZ_LINE]

bool	check_format()
int	open(), fscan(), strlen(), strext()
include	"dfits.com"

begin
	# Open the format file
	fd = open (name, READ_ONLY, TEXT_FILE)

	# Reset counter of keywords (and formats) stored
	nkeywords = 0
 
	# Read the formats (lines) one by one and store it in a
	# table
	while (fscan (fd) != EOF) {

	    # Read line from the file
	    call gargstr (line, SZ_LINE)

	    # Extract keyword from line and test it
	    ip =1
	    keylen = strext (line, ip, " ,", YES, keyword, SZ_LINE)
	    if (keylen == 0) {
		call eprintf ("(%s) - Warning: No keyword found (skipped)\n")
		    call pargstr (line)
		next
	    } else if (keylen > SZ_KEYWORD) {
		call eprintf ("(%s) - Warning: Keyword too long (skipped) \n")
		    call pargstr (line)
		next
	    } else
	        call strupr (keyword)

	    # Extract format from line and test it
	    fmtlen = strext (line, ip, " ", YES, format, SZ_LINE)
	    if (check_format (format)) {
		if (strlen (format) > SZ_FORMAT - 1) {
		    call eprintf ("(%s) - Warning: Format too long (skipped)\n")
		        call pargstr (line)
		    next
		}
	    } else {
		call eprintf ( "(%s) - Warning: Bad format (skipped)\n")
		    call pargstr (line)
		next
	    }

	    # Do final adjustemnts to keyword and format and store
	    # them into the tables
	    if (nkeywords < MAX_TABLE) {
		nkeywords = nkeywords + 1
		call salloc (key_table[nkeywords], SZ_KEYWORD + 1, TY_CHAR)
		call strcpy (keyword, Memc[key_table[nkeywords]], SZ_KEYWORD)
		call salloc (fmt_table[nkeywords], SZ_FORMAT + 1, TY_CHAR)
		call strcpy ("%", Memc[fmt_table[nkeywords]], 1)
		call strcat (format, Memc[fmt_table[nkeywords]],
			     strlen (format))
		opt_table[nkeywords] = format[strlen (format)]
	    }

	    # Debug output (true -> debug active)
	    if (false) {
		call eprintf ("keyword = <%s>  format = <%s>  option = <%c>\n")
		    call pargstr (Memc[key_table[nkeywords]])
		    call pargstr (Memc[fmt_table[nkeywords]])
		    call pargc (opt_table[nkeywords])
	    }
	}

	# Close format file
	call close (fd)
end


# CHECK_FORMAT - Verify the syntax of a format string. It returns true if
# it's a legal format and false if not. A default format code is appended
# to the format if it's missing.

bool procedure check_format (format)

char	format[ARB]		# format to parse

char	ch			# last character
int	n			# character index
int	state			# parser state

begin
	n = 1
	state = 0
	repeat {
	    ch = format[n]
	    switch (state) {
	    case 0:
		if (ch == EOS) {
		    call strcat ("s", format, ARB)
		    return true
		} else if (ch == '.') {
		    state = 2
		    n = n + 1
		} else if (ch == '-') {
		    state = 1
		    n = n + 1
		} else if (IS_DIGIT(ch))
		    state = 1
		else if (IS_FORMAT(ch))
		    return true
		else
		    return false
	    case 1:
		if (ch == EOS) {
		    call strcat ("s", format, ARB)
		    return true
		} else if (ch == '.') {
		    state = 2
		    n = n + 1
		} else if (IS_DIGIT(ch))
		    n = n + 1
		else if (IS_FORMAT(ch)) {
		    state = 3
		    n = n + 1
		} else
		    return false
	    case 2:
		if (ch == EOS) {
		    call strcat ("s", format, ARB)
		    return true
		} else if (IS_DIGIT(ch))
		    n = n + 1
		else if (IS_FORMAT(ch)) {
		   state = 3
		   n = n + 1
		} else
		    return false
	    case 3:
		if (ch == EOS)
		    return true
		else
		    return false
	    default:
		call error (0, "Illegal format parser state")
	    }
	}
end
