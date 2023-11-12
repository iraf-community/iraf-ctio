.help directory
.nf

This file contains a set of procedures for traversing directories
recursevely, and get all the file names in it.

Entry points:
	    	   dp = drt_open (vfn, mode)
			drt_close (dp)
	         stat = drt_gfname (dp)


The directory to traverse should be opened with drt_open(). The "vfn"
parameter specifies the virtual file name of the directory and the "mode"
parameter specifies if hidden file names are skipped or not (see diropen.h)
After opening a directory a structure is allocated to store all the
directory parameters.

The drt_close() procedures closes the current opened directory and frees
all memory allocated for the structure.

The drt_gfname() procedure returns the next file name in the directory
and subdirectories under it.Subdirectory names are returned as well.
The value EOF is returned when no more files are found.
.endhelp

include	<error.h>

# Pointer Mem
define	MEMP	Memi

# Constants
define	MAGIC		1810			# magic number
define	STACK_GROW	100			# stack growing factor (files)

# Directory structure
define	LEN_DRT		8			# structure size
define	DRT_MAGIC	Memi[$1+0]		# magic number
define	DRT_FD		Memi[$1+1]		# directory file descriptor
define	DRT_SKIP	Memi[$1+2]		# skip hidden files
define	DRT_ROOT	MEMP[$1+3]		# root directory pointer
define	DRT_STACKLEN	Memi[$1+4]		# stack length
define	DRT_CPOS	Memi[$1+5] 		# current dir. pointer index
define	DRT_FPOS	Memi[$1+6] 		# free directory pointer index
define	DRT_STACK	MEMP[$1+7]		# directory stack

# Stack access
define	DRT_CURR	MEMP[DRT_STACK($1)+DRT_CPOS($1)] # curr. string pointer
define	DRT_FREE	MEMP[DRT_STACK($1)+DRT_FPOS($1)] # free string pointer


# DRT_OPEN -- Open directory for recursive traversal

int procedure drt_open (vfn, mode)

char	vfn[ARB]		# directory name
int	mode			# pass or skip hidden files ?

char	err[SZ_LINE]		# error message
int	fd			# directory file descriptor
int	len			# directory name length
pointer	dir			# pointer to directory string
pointer	dp			# directory structure pointer
pointer	sp

int	diropen()
int	strlen()

begin
	# Allocate string memory
	call smark (sp)
	call salloc (dir, SZ_PATHNAME, TY_CHAR)

	# Try to open directory
	ifnoerr (fd = diropen (vfn, mode)) {

	    # Append a trailing slash to the directory
	    # name if it doesn't end in a '/' or in a '$'
	    len = strlen (vfn)
	    if (vfn[len] == '/' || vfn[len] == '$') {
		call sprintf (Memc[dir], SZ_PATHNAME, "%s")
		    call pargstr (vfn)
	    } else {
		call sprintf (Memc[dir], SZ_PATHNAME, "%s/")
		    call pargstr (vfn)
	    }

	    # Allocate space for directory structure,
	    # and initialize it
	    call malloc (dp, LEN_DRT, TY_STRUCT)
	    DRT_MAGIC (dp) = MAGIC
	    DRT_STACKLEN (dp) = STACK_GROW
	    DRT_FD (dp) = fd
	    DRT_SKIP (dp) = mode
	    DRT_CPOS (dp) = 0	# top of stack
	    DRT_FPOS (dp) = 1

	    # Allocate space for directory stack
	    call malloc (DRT_STACK (dp), DRT_STACKLEN (dp), TY_POINTER)

	    # Store directory name in the root directory
	    # name, and in the top of the stack 
	    call malloc (DRT_ROOT (dp), SZ_PATHNAME, TY_CHAR)
	    call strcpy (Memc[dir], Memc[DRT_ROOT (dp)], SZ_PATHNAME)
	    len = strlen (Memc[dir])
	    call malloc (DRT_CURR (dp), len, TY_CHAR)
	    call strcpy (Memc[dir], Memc[DRT_CURR (dp)], len)

	    # Free memory and return pointer
	    call sfree (sp)
	    return (dp)

	} else {
	    # Free memory and issue error message
	    call sfree (sp)
	    call sprintf (err, SZ_LINE, "drt_open: Can't open directory (%s)")
		call pargstr (vfn)
	    call error (0, err)
	}
end


# DRT_CLOSE -- Close directory

procedure drt_close (dp)

pointer	dp			# directory structure pointer

begin
	# Test pointer and magic number
	if (dp == NULL)
	    call error (0, "drt_close: Null directory pointer")
	else if (DRT_MAGIC (dp) != MAGIC)
	    call error (0, "drt_close: Bad magic number")

	# Free string space
	for (DRT_CPOS (dp) = 0; DRT_CPOS (dp) < DRT_FPOS (dp);
	     DRT_CPOS (dp) = DRT_CPOS (dp) + 1)
	    call mfree (DRT_CURR (dp), TY_CHAR)

	# Free structure space
	call mfree (DRT_ROOT (dp), TY_CHAR)
	call mfree (DRT_STACK (dp), TY_POINTER)
	call mfree (dp, TY_STRUCT)
end


# DRT_GFNAME -- Get next file name in directory. Return EOF when no
# more files are found. The file name returned is the full file name.

int procedure drt_gfname (dp, outname, maxch)

pointer	dp				# directory structure pointer
char	outname[ARB]			# output name
int	maxch				# max number of characters

int	len				# output string length
pointer	filename			# file name (from getline)
pointer	fullname			# full file name
pointer	junk
pointer	sp

bool	strne()
int	getline()
int	diropen(), isdirectory()
int	strlen()

begin
	# Test pointer and magic number
	if (dp == NULL)
	    call error (0, "drt_gfname: Null directory pointer")
	else if (DRT_MAGIC (dp) != MAGIC)
	    call error (0, "drt_gfname: Bad magic number")

	# Test if this procedure is being called after the
	# file, and directory list are exhausted
	if (DRT_CPOS (dp) == DRT_FPOS (dp)) {
	    call strcpy ("", outname, maxch)
	    return (EOF)
	}

	# Allocate memory for strings
	call smark (sp)
	call salloc (filename, SZ_LINE, TY_CHAR)
	call salloc (fullname, SZ_PATHNAME, TY_CHAR)
	call salloc (junk, SZ_PATHNAME, TY_CHAR)

	# Loop until a file name is returned
	while (getline (DRT_FD (dp), Memc[filename]) == EOF) {

	    # Close current directory
	    call close (DRT_FD (dp))

	    # Loop advancing to the next directory in the
	    # stack until either the stack is empty or the
	    # directory can be opened.
	    repeat {
	        DRT_CPOS (dp) = DRT_CPOS (dp) + 1
	        if (DRT_CPOS (dp) == DRT_FPOS (dp)) {
	    	    call strcpy ("", outname, maxch)
		    return (EOF)
	        } else iferr (DRT_FD (dp) = diropen (Memc[DRT_CURR (dp)],
			      DRT_SKIP (dp))) {
		    call erract (EA_WARN)
		    next
		} else {
		    call strcpy (Memc[DRT_CURR (dp)], Memc[DRT_ROOT (dp)],
				 SZ_PATHNAME)
		    break
	        }
	    }
	}

	# Delete trailing newline and prepend root name
	Memc[filename + strlen (Memc[filename]) - 1] = EOS
	call sprintf (Memc[fullname], SZ_PATHNAME, "%s%s")
	    call pargstr (Memc[DRT_ROOT (dp)])
	    call pargstr (Memc[filename])

	# Check if file name is a directory and add it to the
	# stack only if it's not the current directory name (.)
	# or the parent directory name (..)
	if (isdirectory (Memc[fullname], Memc[junk], SZ_PATHNAME) != 0 &&
	    strne (Memc[filename], ".") && strne (Memc[filename], "..")) {

	    # Check if there is enough stack space
	    if (DRT_FPOS (dp) == DRT_STACKLEN (dp)) {
		DRT_STACKLEN (dp) = DRT_STACKLEN (dp) + STACK_GROW
		call realloc (DRT_STACK (dp), DRT_STACKLEN (dp), TY_POINTER)
	    }

	    # Add directory name to the stack
	    len = strlen (Memc[fullname]) + 1
	    call malloc (DRT_FREE (dp), len, TY_CHAR)
	    call sprintf (Memc[DRT_FREE (dp)], len, "%s/")
		call pargstr (Memc[fullname])

	    # Advance free position index
	    DRT_FPOS (dp) = DRT_FPOS (dp) + 1
	}

	# Copy file name to output string
	call strcpy (Memc[fullname], outname, maxch)

	# Free memory, and return
	call sfree (sp)
	return (OK)
end
