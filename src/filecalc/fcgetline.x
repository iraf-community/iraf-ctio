include	<ctype.h>
include	"filecalc.h"


# Comment character in input lines. Anything to the right of the first
# ocurrence of this character in the line is ignored.
define	COMMENT		"#"


# FC_RGETLINE -- Read the next non-white line from a file within line ranges.
# It skips anything after the comment character, empty lines, and lines
# containing only blanks. It returns the line read, and increments the line
# counter used to keep track of the line range. The line counter must be
# initialized to zero by the caller.

int procedure fc_rgetline (fd, ranges, linenum, line, maxch)

int	fd			# file descriptor
int	ranges[3, MAX_RANGES]	# line range array
int	linenum			# line counter (output)
char	line[maxch]		# output line (output)
int	maxch			# max. number of characters in line

int	len

bool	is_in_range()
int	getlline()
int	fc_trimline()

begin
#call eprintf ("fc_getline: fd=%d, linenum=%d, maxch=%d\n")
#call pargi (fd)
#call pargi (linenum)
#call pargi (maxch)

	# Loop reading lines from file until a non-empty line is found
	repeat {

	    # Loop reading lines until the line is within the
	    # range specified in the line range. Return EOF if
	    # the end of the file is reached.
	    repeat {
		if (getlline (fd, line, maxch) == EOF)
		    return (EOF)
		linenum = linenum + 1
	    } until (is_in_range (ranges, linenum))

	    # Return the line length if the trimmed line is not
	    # empty. Otherwise continue with the next line.
	    len = fc_trimline (line)
	    if (len > 0)
		return (len)
	    else
		next
	}
end


# FC_GETLINE -- Read the next non-white line from a file. It skips anything
# after the comment character, empty lines, and lines containing only blanks.
# It returns the line length or EOF if the end of the file is reached.

int procedure fc_getline (fd, line, maxch)

int	fd			# file descriptor
char	line[maxch]		# output line (output)
int	maxch			# max. number of characters in line

int	len

int	getlline()
int	fc_trimline()

begin
	# Loop reading lines from file until a non-empty line is
	# found. Return the line length if that's the case.
	while (getlline (fd, line, maxch) != EOF) {
	    len = fc_trimline (line)
	    if (len > 0)
		return (len)
	    else
		next
	}

	# The program will get here only if the end of file was reached
	return (EOF)
end


# FC_TRIMLINE -- Take out comments, any newline characters, and blanks from
# the line. The operation is performed in place. It returns the line length,
# or zero if the line is empty after the trimming.

int procedure fc_trimline (line)

char	line[ARB]		# line to trim

int	n, len

int	stridx(), strlen()

begin
	# Discard anything after the first comment character in the line
	n = stridx (COMMENT, line)
	if (n > 0)
	    line[n] = EOS

	# Get rid of a possible newline at the end of the line
	len = strlen (line)
	if (line[len] == '\n') {
	    line[len] = EOS
	    len = len - 1
	}

	# Return the line length if it contains non-white space characters
	do n = 1, len {
	    if (!IS_WHITE (line[n]))
		return (len)
	}

	# The program will get here only if the line is empty or blank
	return (0)
end
