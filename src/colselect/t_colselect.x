include <ctype.h>

define 	MAX_COLUMNS	100
define 	MAX_LINES	10000
define	MIN_LINE	1
define	MAX_LINE	9999
define	MIN_COL		1
define	MAX_COL		SZ_LINE
define	LEN_WS		3


# T_COLSELECT -- Extract fixed column ranges from specified lines of 
# an input list. A new list consisting of the extracted columns is output.
# Which lines and columns to extract is specified by the user. Missing
# or blank columns can be optinally filled with a given string.

procedure t_colselect ()

pointer	sp, c_str, l_str, r_str, fin
bool	replace, name
int	list
int	lines[3, MAX_LINES], nlines
int	columns[3,MAX_COLUMNS], ncols

bool	clgetb()
int	decode_ranges()
int	clpopni(), clgfil()

begin
	# Allocate space on stack for char buffers
	call smark (sp)
	call salloc (c_str,  SZ_LINE, TY_CHAR)
	call salloc (l_str,  SZ_LINE, TY_CHAR)
	call salloc (r_str,  SZ_LINE, TY_CHAR)
	call salloc (fin,    SZ_LINE, TY_CHAR)

	# Open template of input files
	list = clpopni ("files")

	# Get the lines, columns to be extracted, and the
	# replace string to use.
	call clgstr ("columns", Memc[c_str], SZ_LINE)
	call clgstr ("lines", Memc[l_str], SZ_LINE)
	call clgstr ("repstr", Memc[r_str], SZ_LINE)

	# Get boolean parameters
	replace = clgetb ("replace")
	name = clgetb ("print_file_names")

	# Columns will be accessed in ascending order
	if (decode_ranges (Memc[c_str], columns, MAX_COLUMNS, ncols) == ERR)
	    call error (0, "Error in column specification")

	# Lines range will be accessed in ascending order
	if (decode_ranges (Memc[l_str], lines, MAX_LINES, nlines) == ERR) 
	    call error (0, "Error in line specification")

	# While list of input files is not depleted, extract columns
	while (clgfil (list, Memc[fin], SZ_FNAME) != EOF) 
	    call col_xtract (Memc[fin], lines, columns, Memc[r_str],
			     replace, name)

	call clpcls (list)
	call sfree (sp)
end


# COL_XTRACT -- Filter out lines from which columns are to be extracted.
# Called once per input file, COL_XTRACT calls COL_PRECORD to process
# each extracted line.

procedure col_xtract (in_fname, lines, columns, repstr, replace, name)

char	in_fname[SZ_FNAME]		# Input file name
int	lines[3,MAX_LINES]		# Ranges of lines to be extracted
int	columns[MAX_COLUMNS]		# Ranges of columns to be extracted
char	repstr[SZ_LINE]			# Replace string
bool	replace				# Replace missing columns (y/n)?
bool	name				# Print file name in each line (y/n)?

pointer	sp, lbuf
int	in, in_line

bool	is_in_range()
int	strlen()
int	open(), getlongline()
errchk	salloc, open, getlongline, col_precord

begin
	# Allocate space for line buffer
	call smark (sp)
	call salloc (lbuf, SZ_LINE, TY_CHAR)

	# Open input file
	in = open (in_fname, READ_ONLY, TEXT_FILE)

	# Position to specified input line
	in_line = 0
	repeat {
	    repeat {
	        if (getlongline (in, Memc[lbuf], SZ_LINE, in_line) == EOF)
	            return
	    } until (is_in_range (lines, in_line))

	    # Discard newline at the end of the line
	    Memc[lbuf + strlen (Memc[lbuf]) - 1] = EOS

	    # Extract colums for the current line
	    call col_precord (in_fname, Memc[lbuf], columns, repstr,
			      replace, name)
	}	

	# Free line buffer
	call sfree (sp)
end


# COL_PRECORD -- Extract and output a record of columns.

procedure col_precord (in_fname, linebuf, columns, repstr, replace, name)

char	in_fname[SZ_FNAME]		# Name of input file
int	linebuf[SZ_LINE]		# Line containing fields
int	columns[MAX_COLUMNS]		# List of columns to extract
char	repstr[SZ_LINE]			# Replace string
bool	replace				# Replace missing columns (y/n)?
bool	name				# Print name in output line (y/n)?

char	word[SZ_LINE]
int	i, n

bool	strwht()
int	strsubs()

begin
	# Print file name as first field of output list?
	if (name) {
	    call printf ("%s\t")
		call pargstr (in_fname)
	}

	# Scan all column ranges, and extract them from
	# the input line.
	i = 1
	while (columns[i] != NULL) {

	    # Extract substring from input line. If the substring is
	    # empty or blank, replace it by a replacement string
	    n = strsubs (linebuf, columns[i], columns[i+1], word, SZ_LINE)
	    if ((n == 0 || strwht (word)) && replace)
		call strcpy (repstr, word, SZ_LINE)

	    # Print extracted columns
	    call printf ("%s\t")
		call pargstr (word)

	    i = i + 3
	}

	call printf ("\n")
end
