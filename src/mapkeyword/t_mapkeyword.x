include	<error.h>
include <pkg/xtanswer.h>

# Symbol structure.
define	LEN_MPKSTRUCT	2			# structure length
define	MPK_OFFSET	Memi[$1 + 0]		# map string offset
define	MPK_USED	Memi[$1 + 1]		# string used ? (YES/NO)


# T_MAPKEYWORD -- Replace image header keyword values with other values
# specified in a text file. The task runs over an image list.

procedure t_mapkeyword ()

bool	verify			# verify each operation ?
bool	show			# print record of each operation ?
bool	noop			# echo operation without performing it ?
bool	check			# check for unused values ?
int	inlist			# input file list
int	answer			# user's answer
pointer	image			# image name
pointer	table			# table file name
pointer	keyword			# keyword name
pointer	stp			# symbol table pointer
pointer	im			# image descriptor
pointer	sym
pointer	sp

bool	clgetb()
int	clpopnu(), clgfil()
pointer	sthead(), stnext()
pointer	stname(), strefsbuf()
pointer	immap()

begin
	# Allocate string space
	call smark (sp)
	call salloc (image,   SZ_FNAME, TY_CHAR)
	call salloc (table,   SZ_FNAME, TY_CHAR)
	call salloc (keyword, SZ_LINE,  TY_CHAR)

	# Get task parameters
	inlist   = clpopnu ("input")
	call clgstr ("keyword", Memc[keyword], SZ_LINE)
	call clgstr ("table",   Memc[table],   SZ_FNAME)
	verify   = clgetb ("verify")
	show     = clgetb ("show")
	noop     = clgetb ("noop")
	check    = clgetb ("check")

	# Read table into a symbol table
	call mpk_get (Memc[table], stp)

	# Initialize
	if (verify)
	    answer = YES
	else
	    answer = ALWAYSYES

	# Loop over all files in input list
	while (clgfil (inlist, Memc[image], SZ_FNAME) != EOF) {
	    
	    # Open input image
	    iferr (im = immap (Memc[image], READ_WRITE, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Process input file
	    call mpk_proc (im, Memc[image], Memc[keyword], stp,
			   show, noop, answer)
	    # Close image
	    call imunmap (im)

	    # Stop the loop if the user wishes to do so
	    if (answer == ALWAYSNO)
		break
	}

	# Check symbol table looking for keyword values not referenced,
	# but present in the table. Issue a waning message for each one
	# of this values. This check is performed only if all the images
	# in the input list were processed.
	if (check && answer != ALWAYSNO) {
	    sym = sthead (stp)
	    while (sym != NULL) {
		if (MPK_USED (sym) == NO) {
		    call eprintf ("Keyword [%s] mapped to [%s] never used\n")
			call pargstr (Memc[stname (stp, sym)])
			call pargstr (Memc[strefsbuf (stp, MPK_OFFSET (sym))])
		}
		sym = stnext (stp, sym)
	    }
	}

	# Close everything
	call clpcls  (inlist)
	call stclose (stp)
	call sfree   (sp)
end


# MPK_GET -- Read the mapping table from a file and store it into a symbol
# table in memory. It aborts the task if the file cannot nbe opened.

procedure mpk_get (table, stp)

char	table[ARB]		# table file name
pointer	stp			# symbol table pointer (output)

int	fd			# file descriptor
int	nlines			# line counter
pointer	sym			# symbol pointer
pointer	key			# keyword value
pointer	map			# keyword mapping
pointer	sp

int	open(), fscan(), nscan()
int	stpstr()
pointer	stopen(), stfind(), stenter()

begin
	# Open table file
	fd = open (table, READ_ONLY, TEXT_FILE)

	# Allocate memory
	call smark (sp)
	call salloc (key,  SZ_LINE, TY_CHAR)
	call salloc (map, SZ_LINE, TY_CHAR)

	# Open symbol table
	stp = stopen ("keywords", 100, 50, 20 * SZ_LINE)

	# Loop over input lines
	nlines = 0
	while (fscan (fd) != EOF) {

	    # Get keyword value and mapping
	    call gargwrd (Memc[key], SZ_LINE)
	    call gargwrd (Memc[map], SZ_LINE)

	    # Count lines
	    nlines = nlines + 1

	    # Check line consistency
	    if (nscan () != 2) {
		call eprintf ("Incomplete line in table [%s] at line %d\n")
		    call pargstr (table)
		    call pargi   (nlines)
	    }

	    # Enter matching string into symbol table if it was
	    # not already there, and set used flag to no. Otherwise
	    # skip it and issue warning message.
	    if (stfind (stp, Memc[key]) == NULL) {
		sym = stenter (stp, Memc[key], LEN_MPKSTRUCT)
		MPK_OFFSET (sym) = stpstr (stp, Memc[map], 0)
		MPK_USED   (sym) = NO
	    } else {
		call eprintf ("Duplicated keyword value [%s] at line %d\n")
		    call pargstr (Memc[key])
		    call pargi   (nlines)
	    }
	}

	# Free memory and close file
	call sfree (sp)
	call close (fd)
end


# MPK_PROC -- Process a single image.

procedure mpk_proc (im, image, keyword, stp, show, noop, answer)

int	im			# image descriptor
char	image[ARB]		# image name
char	keyword[ARB]		# keyword to search
pointer	stp			# association table pointer
bool	show			# ?
bool	noop			# no operation ?
int	answer			# user's answer (output)

pointer	sym			# symbol pointer
pointer	map			# mapped value
pointer	prompt			# prompt to the user
pointer	keyval			# input line
pointer	sp, str

int	stridx()
pointer	stfind(), strefsbuf()

begin
	# Allocate memory
	call smark  (sp)
	call salloc (keyval, SZ_LINE, TY_CHAR)
	call salloc (map,    SZ_LINE, TY_CHAR)
	call salloc (prompt, SZ_LINE, TY_CHAR)
	call salloc (str,    SZ_LINE, TY_CHAR)

	# Get keyword value as a string
	iferr (call imgstr (im, keyword, Memc[keyval], SZ_LINE)) {
	    call eprintf ("Keyword [%s] not found in image [%s]\n")
		call pargstr (keyword)
		call pargstr (image)
	    call sfree (sp)
	    return
	}

	# Look for the keyword value in the table, and replace it with the
	# mapped value in the table if it was found. Otherwise issue a
	# warning message.
	sym = stfind (stp, Memc[keyval])
	if (sym != NULL) {

	    # Get keyword mapping. If the mapped value contains blanks,
	    # and if the keyword value was not a single word, then enclose
	    # the mappped value between single quotes. This guarantees
	    # (to some extent) that when a non-string keyword is replaced
	    # by a multi-word string it will be enclosed between single
	    # quotes to make it a single entity.
	    call strcpy (Memc[strefsbuf (stp, MPK_OFFSET (sym))],
			 Memc[str], SZ_LINE)
	    if (stridx (" ", Memc[str]) != 0 && 
		stridx (" ", Memc[keyval]) == 0) {
		call sprintf (Memc[map], SZ_LINE, "\'%s\'")
		    call pargstr (Memc[str])
	    } else {
		call sprintf (Memc[map], SZ_LINE, "%s")
		    call pargstr (Memc[str])
	    }

	    # Change keyword value with the one stored in the table
	    if (show && answer != ALWAYSYES) {
		call sprintf (Memc[prompt], SZ_LINE,
		    "Image [%s], Keyword [%s]: [%s] -> [%s]")
		    call pargstr (image)
		    call pargstr (keyword)
		    call pargstr (Memc[keyval])
		    call pargstr (Memc[map])
	    }
	    
	    # Prompt the user if the last answer was either YES or NO,
	    # i.e. the user wants to be prompted each time. If the answer
	    # was ALWAYSYES perform the operation blindly, or print it
	    # as it's being performed (show switch set). The noop switch
	    # is checked in both cases.
	    if (answer == YES || answer == NO) {
	        call xt_answer (Memc[prompt], answer)
	        if (answer == YES || answer == ALWAYSYES) {
		    if (!noop)
			call impstr (im, keyword, Memc[map])
		}
	    } else if (answer == ALWAYSYES) {
		if (show) {
		    call printf ("%s\n")
			call pargstr (Memc[prompt])
		}
		if (!noop)
		    call impstr (im, keyword, Memc[map])
	    }

	    # Mark symbol as used (referenced)
	    MPK_USED (sym) = YES

	} else {
	    call eprintf (
		"Keyword value [%s] for image [%s] not found in table\n")
		call pargstr (Memc[keyval])
		call pargstr (image)
	}

	# Free memory
	call sfree (sp)
end
