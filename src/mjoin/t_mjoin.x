include	<error.h>

# Symbol structure.
define	LEN_MJNSTRUCT	2			# structure length
define	MJN_OFFSET	Memi[$1 + 0]		# matching string offset
define	MJN_USED	Memi[$1 + 1]		# string used ? (YES/NO)


# T_MJOIN -- Join files from two text files. Lines can be joined either
# sequentially, or by matching the first string in each line.

procedure t_mjoin ()

bool	discard			# discard matching string ?
bool	match			# match lines ?
bool	warnings		# print warning messages ?
int	inlist			# input file list
int	joinlist		# input file list
int	ofd			# output file descriptor
pointer	output			# output file name
pointer	sp

bool	clgetb()
int	clpopnu()
int	open()

begin
	# Allocate string space
	call smark (sp)
	call salloc (output, SZ_FNAME + 1, TY_CHAR)

	# Get task parameters
	inlist   = clpopnu ("input")
	joinlist = clpopnu ("join")
	call clgstr ("output", Memc[output], SZ_FNAME)
	match    = clgetb ("match")
	discard  = clgetb ("discard")
	warnings = clgetb ("warnings")

	# Open output file
	ofd = open (Memc[output], NEW_FILE, TEXT_FILE)

	# Check whether to match lines by the first identifier or not
	if (match)
	    call mjn_match (inlist, joinlist, ofd, discard, warnings)
	else
	    call mjn_nomatch (inlist, joinlist, ofd, warnings)

	# Close file list and output file
	call clpcls (inlist)
	call clpcls (joinlist)
	call close  (ofd)

	# Free memory
	call sfree (sp)
end


# MJN_MATCH -- Join lines from two lists of text files, matching lines
# by the first string in each line.

procedure mjn_match (inlist, joinlist, ofd, discard, warnings)

int	inlist			# input file list
int	joinlist		# input file list
int	ofd			# output file descriptor
bool	discard			# discard matching string ?
bool	warnings		# print warning messages ?

int	ifd			# input file descriptor
pointer	fname			# input file name
pointer	stp			# join table pointer	
pointer	sym			# symbol pointer
pointer	sp

int	clgfil()
int	open()
pointer	stopen()
pointer	sthead(), stnext()
pointer	stname(), strefsbuf()

begin
	# Allocate string space
	call smark (sp)
	call salloc (fname, SZ_FNAME + 1, TY_CHAR)

	# Open data to join table
	stp = stopen ("join", 100, 50, 20 * SZ_LINE)

	# Loop over all files in input list
	while (clgfil (joinlist, Memc[fname], SZ_FNAME) != EOF) {
	    
	    # Open input file
	    iferr (ifd = open (Memc[fname], READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Process input file
	    call mjn_get (Memc[fname], ifd, stp)

	    # Close input file
	    call close (ifd)
	}

	# Loop over all files in input list
	while (clgfil (inlist, Memc[fname], SZ_FNAME) != EOF) {
	    
	    # Open input file
	    iferr (ifd = open (Memc[fname], READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Process input file
	    call mjn_mjoin (Memc[fname], ifd, stp, ofd, discard, warnings)

	    # Close input file
	    call close (ifd)
	}

	# Traverse symbol table looking for symbols not referenced,
	# and issue warning messages if they are found. The table
	# will be traversed backwards.
	if (warnings) {
	    sym = sthead (stp)
	    while (sym != NULL) {
		if (MJN_USED (sym) == NO) {
		    call eprintf ("line [%s %s] never used\n")
			call pargstr (Memc[stname (stp, sym)])
			call pargstr (Memc[strefsbuf (stp, MJN_OFFSET (sym))])
		}
		sym = stnext (stp, sym)
	    }
	}

	# Close symbol table
	call stclose (stp)

	# Free memory
	call sfree (sp)
end


# MJN_GET -- Read join file and store it into a symbol table for later use.

procedure mjn_get (fname, fd, stp)

char	fname[ARB]		# file name
int	fd			# file descriptor
pointer	stp			# symbol table pointer (output)

int	nlines			# line counter
int	ip
pointer	sym			# symbol pointer
pointer	line			# input line
pointer	match			# matching string
pointer	sp

int	fscan()
int	ctowrd()
int	stpstr()
pointer	stfind(), stenter()

begin
	# Allocate memory
	call smark (sp)
	call salloc (line, SZ_LINE + 1, TY_CHAR)
	call salloc (match, SZ_LINE + 1, TY_CHAR)

	# Loop over input lines
	nlines = 0
	while (fscan (fd) != EOF) {

	    # Get line, and count them
	    call gargstr (Memc[line], SZ_LINE)
	    nlines = nlines + 1

	    # Extract matching name from it. Skip blank lines.
	    ip = 1
	    if (ctowrd (Memc[line], ip, Memc[match], SZ_LINE) == 0)	
		next

	    # Enter matching string into symbol table if it was
	    # not already there, and set used flag to no. Otherwise
	    # skip it and issue warning message.
	    if (stfind (stp, Memc[match]) == NULL) {
		sym = stenter (stp, Memc[match], LEN_MJNSTRUCT)
		MJN_OFFSET (sym) = stpstr (stp, Memc[line + ip - 1], 0)
		MJN_USED (sym) = NO
	    } else {
		call eprintf (
		    "duplicated matching string [%s] in file [%s] at line %d\n")
		    call pargstr (Memc[match])
		    call pargstr (fname)
		    call pargi (nlines)
	    }
	}

	# Free memory
	call sfree (sp)
end


# MJN_MJOIN -- Join lines from two text files, matching lines by the first
# string in each line.

procedure mjn_mjoin (fname, ifd, stp, ofd, discard, warnings)

char	fname			# input file name
int	ifd			# input file descriptor
pointer	stp			# association table pointer
int	ofd			# output file descriptor
bool	discard			# discard matching string ?
bool	warnings		# print warning messages ?

int	nlines			# line counter
int	ip
pointer	sym			# symbol pointer
pointer	line			# input line
pointer	match			# matching string
pointer	sp

int	fscan()
int	ctowrd()
pointer	stfind(), strefsbuf()

begin
	# Allocate memory
	call smark (sp)
	call salloc (line, SZ_LINE + 1, TY_CHAR)
	call salloc (match, SZ_LINE + 1, TY_CHAR)

	# Loop over input lines
	nlines = 0
	while (fscan (ifd) != EOF) {

	    # Get line, and count them
	    call gargstr (Memc[line], SZ_LINE)
	    nlines = nlines + 1

	    # Extract matching name from it.
	    ip = 1
	    if (ctowrd (Memc[line], ip, Memc[match], SZ_LINE) == 0) {
		call fprintf (ofd, "\n")
		next
	    }

	    # Look for the matching string in the symbol table, and
	    # write to the output file.
	    sym = stfind (stp, Memc[match])
	    if (sym != NULL) {

		# If the matching string is found in the symbol table
		# then write the input line along with the the matching
		# line. Optionally write the matching string.
		if (discard) {
		    call fprintf (ofd, "%s  %s\n")
			call pargstr (Memc[line])
			call pargstr (Memc[strefsbuf (stp, MJN_OFFSET (sym))])
		} else {
		    call fprintf (ofd, "%s  %s  %s\n")
			call pargstr (Memc[line])
			call pargstr (Memc[match])
			call pargstr (Memc[strefsbuf (stp, MJN_OFFSET (sym))])
		}

		# Mark symbol as used (referenced)
		MJN_USED (sym) = YES

	    } else {

		# Write the input line
		call fprintf (ofd, "%s\n")
		    call pargstr (Memc[line])

		# Issue warning message because the matching string
		# was not found in the symbol table.
		if (warnings) {
		    call eprintf (
			    "[%s] does not match in file [%s] at line %d\n")
			    call pargstr (Memc[match])
			    call pargstr (fname)
			    call pargi (nlines)
		}
	    }
	}

	# Flush output
	call flush (ofd)

	# Free memory
	call sfree (sp)
end


# MJN_NOMATCH -- Join lines from two lists of text files without matching
# lines by the first string in each line.

procedure mjn_nomatch (inlist, joinlist, ofd, warnings)

int	inlist			# input file list
int	joinlist		# input file list
int	ofd			# output file descriptor
bool	warnings		# print warning messages ?

int	ifd, jfd		# file descriptors
pointer	fname, jname		# file names
pointer	sp

int	clgfil()
int	open()
int	mjn_join()

begin
	# Allocate string space
	call smark (sp)
	call salloc (fname, SZ_FNAME + 1, TY_CHAR)
	call salloc (jname, SZ_FNAME + 1, TY_CHAR)

	# Loop over all files in input list
	while (clgfil (inlist, Memc[fname], SZ_FNAME) != EOF) {
	    
	    # Get file in join list
	    if (clgfil (joinlist, Memc[jname], SZ_FNAME) == EOF) {
		if (warnings)
		    call eprintf ("Join list shorter than input list\n")
		call sfree (sp)
		return
	    }

	    # Open input file
	    iferr (ifd = open (Memc[fname], READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Open join file
	    iferr (jfd = open (Memc[jname], READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Join lines
	    if ((mjn_join (ifd, jfd, ofd) == EOF) && warnings) {
		call eprintf ("File [%s] shorter than [%s]\n")
		    call pargstr (Memc[jname])
		    call pargstr (Memc[fname])
	    }

	    # Close files
	    call close (ifd)
	    call close (jfd)
	}

	# Free memory
	call sfree (sp)
end


# MJN_JOIN -- Join lines from two text files without matching lines by
# the first string in each line.

int procedure mjn_join (ifd, jfd, ofd)

int	ifd			# input file descriptor
int	jfd			# join file descriptor
int	ofd			# output file descriptor

pointer	iline, jline		# input lines
pointer	sp

int	fscan()

begin
	# Allocate string space
	call smark (sp)
	call salloc (iline, SZ_LINE + 1, TY_CHAR)
	call salloc (jline, SZ_LINE + 1, TY_CHAR)

	# Loop over input file
	while (fscan (ifd) != EOF) {

	    # Get iinput line
	    call gargstr (Memc[iline], SZ_LINE)

	    # Get join line, if any
	    if (fscan (jfd) != EOF)
		call gargstr (Memc[jline], SZ_LINE)
	    else {
		call sfree (sp)
		return (EOF)
	    }

	    # Write both lines to the output file
	    call fprintf (ofd, "%s  %s\n")
		call pargstr (Memc[iline])
		call pargstr (Memc[jline])
	}

	# Flush output
	call flush (ofd)

	# Free string space, and return ok
	call sfree (sp)
	return (OK)
end
