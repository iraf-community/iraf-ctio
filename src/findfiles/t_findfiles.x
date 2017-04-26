include	<diropen.h>
include	<mach.h>
include	<pattern.h>

# The following string will be replaced by the file name found
# in the command line sent to the CL. Abreviations are not allowed.
define	REPLACE			"$file"

# File types
define	FILE_TYPES		"|none|plain|directory|"
define	FILE_NONE		1	# any type
define	FILE_PLAIN		2	# plain file
define	FILE_DIRECTORY		3	# directory

# Pattern matching characters. If these metacharacters are present in the
# name to search the full pattern matching is required. Othewise only
# straight string comparison is used.
define	PATCHARS		"*?["


# T_FINDFILES - Recursivley descend a directory hierarchy seeking for files
# that match a given string in their file names, and a given type in their
# file types. It can take two types of action on every file found: print
# its file name or execute a CL command.

procedure t_findfiles ()

bool	exec			# is there a command to execute ?
bool	print			# print file names ?
bool	wait			# wait for command completion ?
bool	match			# file matching ?
bool	usepat			# use pattern matching ?
char	lastch			# last character when generating general name
int	mode			# directory open mode
int	nflush			# number of files before flushing
int	type			# file type
int	ip, op
int	n, junk, offset
pointer	rootdir			# root directory
pointer	name			# name to match
pointer	namepat			# general name pattern to match
pointer	fname			# next file name
pointer	execstr			# command line from the user
pointer	cmdstr			# command line to the CL
pointer	pattern			# compiled pattern
pointer	dummy
pointer	dp			# directory descriptor
pointer	sp

bool	clgetb()
bool	streq(), strne()
int	clgeti(), clgwrd()
int	stridxs(), strldx()
int	patmake(), patmatch()
int	isdirectory()
int	drt_gfname()
pointer	drt_open()

begin
	# Allocate string space
	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (namepat, SZ_LINE, TY_CHAR)
	call salloc (rootdir, SZ_FNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (execstr, SZ_LINE, TY_CHAR)
	call salloc (cmdstr, SZ_LINE, TY_CHAR)
	call salloc (pattern, SZ_LINE, TY_CHAR)
	call salloc (dummy, SZ_LINE, TY_CHAR)

	# Get positional parameters
	call clgstr ("rootdir", Memc[rootdir], SZ_FNAME)
	call clgstr ("name", Memc[name], SZ_FNAME)

	# Get hidden parameters
	type = clgwrd ("type", Memc[dummy], SZ_LINE, FILE_TYPES)
	print = clgetb ("print")
	nflush = clgeti ("nflush")
	call clgstr ("execute", Memc[execstr], SZ_LINE)
	wait = clgetb ("wait")
	if (clgetb ("skip"))
	    mode = SKIP_HIDDEN_FILES
	else
	    mode = PASS_HIDDEN_FILES

	# Set execute command flag
	exec = strne (Memc[execstr], "")

	# An INDEF value in the "nflush" parameter
	# should mean the largest integer
	if (IS_INDEFI (nflush))
	    nflush = MAX_INT

	# Determine if full file name pattern matching is needed,
	# and compile the pattern if necessary. Also convert the
	# file matching pattern into a general pattern string to
	# make use of the pattern maching procedures.
	usepat = (stridxs (PATCHARS, Memc[name]) != 0)
	if (usepat) {

	    # Convert file name pattern into general pattern string
	    Memc[namepat] = CH_BOL
	    op = 1
	    lastch = '\000'
	    for (ip = 0;  Memc[name + ip] != EOS;  ip = ip + 1) {
		if (Memc[name + ip] == CH_CLOSURE &&
		    lastch != CH_ANY && lastch != CH_CCLEND) {
		    Memc[namepat + op] = CH_ANY
		    op = op + 1
		}
		lastch = Memc[name + ip]
		Memc[namepat + op] = lastch
		op = op + 1
	    }
	    Memc[namepat + op + 0] = CH_EOL
	    Memc[namepat + op + 1] = EOS

	    # Compile pattern
	    junk = patmake (Memc[namepat], Memc[pattern], SZ_LINE)
	}

	# Open directory recursively
	dp = drt_open (Memc[rootdir], mode)

	# Loop until no more files can be found in the directory
	n = 0
	while (drt_gfname (dp, Memc[fname], SZ_FNAME) != EOF) {

	    # Determine the position of the last "/" in the name
	    # so that part won't be used for matching the name
	    offset = strldx ("/", Memc[fname])

	    # Determine if there is a file name matching
	    if (usepat)
	        match = (patmatch (Memc[fname + offset], Memc[pattern]) != 0)
	    else
	        match = streq (Memc[fname + offset], Memc[name])
		
	    # Take action if the file name matches the specified name
	    if (match) {
		
		# Skip files that don't match the file type
		switch (type) {
		case FILE_NONE:
		    # no action
		case FILE_PLAIN:
		    if (isdirectory (Memc[fname], Memc[dummy], SZ_LINE) != 0)
			next
		case FILE_DIRECTORY:
		    if (isdirectory (Memc[fname], Memc[dummy], SZ_LINE) == 0)
			next
		default:
		    call error (0, "Illegal file type")
		}

		# Test if print file name
		if (print) {
		    call printf ("%s\n")
		        call pargstr (Memc[fname])
		    n = n + 1
		}

		# Test if execute command. If so, the current file name is
		# replaced in the command line before seinding it to the CL.
		if (exec) {
		    call strrep (Memc[execstr], REPLACE, Memc[fname],
				 Memc[cmdstr], SZ_LINE)
		    if (wait)
			call clcmdw (Memc[cmdstr])
		    else
			call clcmd (Memc[cmdstr])
		}
	    }

	    # Flush standard output after the
	    # specified number of files
	    if (n >= nflush) {
		call flush (STDOUT)
		n = 0
	    }
	}

	# Flush standard output
	call flush (STDOUT)

	# Close directory
	call drt_close (dp)

	# Free memory
	call sfree (sp)
end
