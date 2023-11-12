.help fcfiles
Data file handler

This routines are used to handle the input files.

All the information is stored in a memory structure consisting of a main
structure plus two subsructures. The main structure stores the information
about how many input files are being used. There is one "file substructure"
per input file, containing the file descriptor and other miscelaneous
information about the file. There is one "data substructure" per input file
containing the data of each column in the file. This substructure stores
only one line at a time.

The structure is allocated with fc_alloc(), and it can be freed with
fc_ffree(). The file descriptor and its file name is entered by using
fc_pufile(). The latter allocates the "file substructure" for the input
file. Data is read from the input files, one line at time, with
fc_fgetlines().  This data can be retrieved afterwards with fc_fdata(),
before calling fc_fgetlines() again.

A debugging procedure to dump the file structure and its substructures to
the standard error is provided. This procedure is called fc_fdump().

.nf
Entry points:
		 fptr = fc_falloc    (nfiles)
			fc_ffree     (fptr)

			fc_fputfile  (fptr, fd, fname)

	       OK|EOF = fc_fgetlines (fptr, ranges, warnings)

		 type = fc_fdata     (fptr, fnum, cnum, warnings,
				      ival, rval, dval, strval, maxch)

			fc_fdump     (fptr)
.fi
.endhelp

include	<error.h>
include	<lexnum.h>
include	"filecalc.h"

# Pointer Mem
define	MEMP		Memi

# File structure
define	LEN_FSTRUCT	3				# structure length
define	FS_NFILES	Memi[$1+0]			# number of files
define	FS_SIZE		Memi[$1+1]			# allocated files
define	FS_FSTRUCTS	MEMP[$1+2]			# file sub-structures

# File sub-structure
define	LEN_FSSTRUCT	11				# structure length
define	FSS_FD		Memi[$1+($2-1)*LEN_FSSTRUCT+0]	# file descriptor
define	FSS_NCOLS	Memi[$1+($2-1)*LEN_FSSTRUCT+1]	# number of columns
define	FSS_MAXCOL	Memi[$1+($2-1)*LEN_FSSTRUCT+2]	# allocated columns
define	FSS_NLINES	Memi[$1+($2-1)*LEN_FSSTRUCT+3]	# line counter
define	FSS_COLMIN	MEMP[$1+($2-1)*LEN_FSSTRUCT+4]	# minimum of columns
define	FSS_COLMAX	MEMP[$1+($2-1)*LEN_FSSTRUCT+5]	# maximum of columns
define	FSS_COLAVG	MEMP[$1+($2-1)*LEN_FSSTRUCT+6]	# average of columns
define	FSS_COLMEDIAN	MEMP[$1+($2-1)*LEN_FSSTRUCT+7]	# median of columns
define	FSS_COLMODE	MEMP[$1+($2-1)*LEN_FSSTRUCT+8]	# mode of columns
define	FSS_COLSIGMA	MEMP[$1+($2-1)*LEN_FSSTRUCT+9]	# sigma of columns
define	FSS_DATA	MEMP[$1+($2-1)*LEN_FSSTRUCT+10]	# data sub-structures


# Data sub-structure. The data buffer consists of an arbitrary number of
# this elements that are used to store the data in the input file columns.
define	LEN_DSSTRUCT	(5 + SZ_LINE)
define	DSS_DVAL	Memd[P2D($1+($2-1)*LEN_DSSTRUCT+0)]	# double value
define	DSS_RVAL	Memr[    $1+($2-1)*LEN_DSSTRUCT+2 ]	# real value
define	DSS_IVAL	Memi[    $1+($2-1)*LEN_DSSTRUCT+3 ]	# integer value
define	DSS_TYPE	Memi[    $1+($2-1)*LEN_DSSTRUCT+4 ]	# data type
define	DSS_STRVAL	Memc[P2C($1+($2-1)*LEN_DSSTRUCT+5)]	# string value


# Number of elements (columns) that are allocated in the data buffer the
# first time the bufferis allocated. This number is also used as an increment
# when the data buffer is reallocated.
define	START_NCOLS	5


# FC_FALLOC -- Allocate file structure.

pointer procedure fc_falloc (nfiles)

int	nfiles			# number of files

int	i, size
pointer	fptr

begin
#call eprintf ("fc_falloc: nfiles=%d\n")
#call pargi (nfiles)

	# Set the maximum number of files equal to the current
	# number of files plus an additive factor in order to
	# reduce memory reallocation.
	size = nfiles + 3

	# Allocate and initialize the file structure
	call malloc (fptr, LEN_FSTRUCT, TY_STRUCT)
	FS_NFILES (fptr) = 0
	FS_SIZE   (fptr) = size

	# Allocate the file sub-structures
	call malloc (FS_FSTRUCTS (fptr), size * LEN_FSSTRUCT, TY_STRUCT)

	# Initialize the file sub-structures
	do i = 1, size
	    call fc_finit (FS_FSTRUCTS (fptr), i)

	# Return pointer to file structures
	return (fptr)
end


# FC_FFREE -- Free file structure.

procedure fc_ffree (fptr)

pointer	fptr			# file structure pointer

int	i, nfiles
pointer	fsptr

begin
	# Get number of files and the pointer to the file
	# sub-structures from the file structure
	nfiles = FS_NFILES   (fptr)
	fsptr  = FS_FSTRUCTS (fptr)

	# Close all opened files
	do i = 1, nfiles {
	    if (!IS_INDEFI (FSS_FD (fsptr, i)))
	        call close (FSS_FD (fsptr, i))
	}

	# Free data sub-structures
	do i = 1, nfiles {
	    if (FSS_DATA (fsptr, i) != NULL)
	        call mfree (FSS_DATA (fsptr, i), TY_STRUCT)
	}

	# Free file sub-structures and file structure
	call mfree (fsptr, TY_STRUCT)
	call mfree (fptr,  TY_STRUCT)
end


# FC_FINIT -- Initialize the file sub-structure for a given file number.

procedure fc_finit (fsptr, fnum)

pointer	fsptr			# file sub-structure pointer
int	fnum			# file number

begin
	FSS_FD        (fsptr, fnum) = INDEFI
	FSS_NCOLS     (fsptr, fnum) = 0
	FSS_MAXCOL    (fsptr, fnum) = 0
	FSS_NLINES    (fsptr, fnum) = 0
	FSS_COLMIN    (fsptr, fnum) = NULL
	FSS_COLMAX    (fsptr, fnum) = NULL
	FSS_COLAVG    (fsptr, fnum) = NULL
	FSS_COLMEDIAN (fsptr, fnum) = NULL
	FSS_COLMODE   (fsptr, fnum) = NULL
	FSS_COLSIGMA  (fsptr, fnum) = NULL
	FSS_DATA      (fsptr, fnum) = NULL
end


# FC_FPUTFILE -- Enter file descriptor and name into the next free file
# sub-structure. So far the file name is not stored in the structure, but
# it might in the future.

procedure fc_fputfile (fptr, fd, fname)

pointer	fptr			# file structure pointer
int	fd			# file descriptor
char	fname[ARB]		# file name

int	i

begin
#call eprintf ("fc_putfile: fptr=%x, fd=%d, fname=%s\n")
#call pargi (fptr)
#call pargi (fd)
#call pargstr (fname)

	# Increment the file counter
	FS_NFILES (fptr) = FS_NFILES (fptr) + 1

	# Reallocate memory if no more file sub-structures are available.
	if (FS_NFILES (fptr) > FS_SIZE (fptr)) {

	    # Increment size and reallocate buffer
	    FS_SIZE (fptr) = FS_SIZE (fptr) + 5
	    call realloc (FS_FSTRUCTS (fptr), FS_SIZE (fptr), TY_STRUCT)

	    # Initialize new file sub-structures
	    do i = FS_NFILES (fptr), FS_SIZE (fptr)
		call fc_finit (FS_FSTRUCTS (fptr), i)
	}

	# Enter file descriptor into the structure
	FSS_FD (FS_FSTRUCTS (fptr), FS_NFILES (fptr)) = fd
end


# FC_FGETLINES -- Get one line from all input files, split lines into
# columns, and store column data into the data substructure. Return EOF
# if the end of file is reached in all the input files.

int procedure fc_fgetlines (fptr, ranges, warnings)

pointer	fptr			# file structure pointer
int	ranges[3, MAX_RANGES]	# line range array
bool	warnings		# print warnings ?

bool	alleof
int	ip1, ip2, ip3
int	fnum, dummy
int	nfiles
int	ival
real	rval
double	dval
pointer	fsptr, dsptr
pointer	sp, line, word

int	ctoi(), ctor(), ctod(), ctowrd()
int	stridx()
int	lexnum()
int	fc_rgetline()

begin
#call eprintf ("fc_fgetlines: fptr=%x, warnings=%b\n")
#call pargi (fptr)
#call pargb (warnings)

	# Allocate memory
	call smark (sp)
	call salloc (line, 10 * SZ_LINE, TY_CHAR)
	call salloc (word, SZ_LINE, TY_CHAR)

	# Initialize the flag that indicates the end of all files
	alleof = true

	# Get number of files and the pointer to the file
	# sub-structures from the file structure
	nfiles = FS_NFILES   (fptr)
	fsptr  = FS_FSTRUCTS (fptr)

	# Loop over all input files
	do fnum = 1, nfiles {

	    # Increment line counter
	    # FSS_NLINES (fsptr, fnum) = FSS_NLINES (fsptr, fnum) + 1

	    # Reset number of columns in the file structure
	    FSS_NCOLS (fsptr, fnum) = 0

	    # Loop over lines in the input file until a non-comment
	    # and non-blank line is found.
	    if (fc_rgetline (FSS_FD (fsptr, fnum), ranges,
			     FSS_NLINES (fsptr, fnum),
			     Memc[line], SZ_LINE) != EOF) {

		# Loop over all words in the input line
		ip1 = 1
		while (ctowrd (Memc[line], ip1, Memc[word], SZ_LINE) != 0) {

		    # Count columns
		    FSS_NCOLS (fsptr, fnum) = FSS_NCOLS (fsptr, fnum) + 1

		    # Allocate more space to store columns data if needed. 
		    if (FSS_NCOLS (fsptr, fnum) > FSS_MAXCOL (fsptr, fnum)) {
			if (FSS_DATA (fsptr, fnum) == NULL) {
			    FSS_MAXCOL (fsptr, fnum) = START_NCOLS
			    call malloc (FSS_DATA (fsptr, fnum), LEN_DSSTRUCT *
					 FSS_MAXCOL (fsptr, fnum), TY_STRUCT)
			} else {
			    FSS_MAXCOL (fsptr, fnum) = FSS_MAXCOL (fsptr,
						       fnum) + START_NCOLS	
			    call realloc (FSS_DATA (fsptr, fnum),
					  LEN_DSSTRUCT *
					  FSS_MAXCOL (fsptr, fnum), TY_STRUCT)
			}
		    }

		    # Get pointer to data substructure
		    dsptr = FSS_DATA (fsptr, fnum)

		    # Convert word into the appropiate data type
		    ip2 = 1
		    switch (lexnum (Memc[word], ip2, dummy)) {
		    case LEX_OCTAL, LEX_DECIMAL, LEX_HEX:
			ip3 = 1
			DSS_TYPE (dsptr, FSS_NCOLS (fsptr, fnum)) = TY_INT
			if (ctoi (Memc[word], ip3, ival) == 0) {
			    if (warnings) {
				call eprintf (
				    "Cannot convert [%s] to integer\n")
				    call pargstr (Memc[word])
			    }
			    DSS_IVAL (dsptr, FSS_NCOLS (fsptr, fnum)) = INDEFI
			} else
			    DSS_IVAL (dsptr, FSS_NCOLS (fsptr, fnum)) = ival

		    case LEX_REAL:
			if (stridx ("d", Memc[word]) > 0 &&
			    stridx ("D", Memc[word]) > 0) {
			    DSS_TYPE (dsptr,
				      FSS_NCOLS (fsptr, fnum)) = TY_DOUBLE
			    ip3 = 1
			    if (ctod (Memc[word], ip3, dval) == 0) {
				if (warnings) {
				    call eprintf (
					"Cannot convert [%s] to double\n")
					call pargstr (Memc[word])
				    DSS_DVAL (dsptr,
					      FSS_NCOLS (fsptr, fnum)) = INDEFD
				}
			    } else
			        DSS_DVAL (dsptr,
					  FSS_NCOLS (fsptr, fnum)) = dval
			} else {
			    DSS_TYPE (dsptr, FSS_NCOLS (fsptr, fnum)) = TY_REAL
			    ip3 = 1
			    if (ctor (Memc[word], ip3, rval) == 0) {
				if (warnings) {
				    call eprintf (
					"Cannot convert [%s] to real\n")
					call pargstr (Memc[word])
				    DSS_RVAL (dsptr,
					      FSS_NCOLS (fsptr, fnum)) = INDEFR
				}
			    } else
			        DSS_RVAL (dsptr,
					  FSS_NCOLS (fsptr, fnum)) = rval
			}

		    default:
			DSS_TYPE (dsptr, FSS_NCOLS (fsptr, fnum)) = TY_CHAR
			call strcpy (Memc[word],
				     DSS_STRVAL (dsptr, FSS_NCOLS (fsptr,
						 fnum)), SZ_LINE)
		    }

		    # Reset all end of file flag
		    alleof = false

		} # ctowrd

	    } else {
	    
		# Issue warnig message if the end of the file was reached
		if (warnings && nfiles > 1) {
		    call eprintf ("End of file reached in file #%d\n")
			call pargi (fnum)
		}
	    }

	} # do

	# Free memory
	call sfree (sp)

	# Return EOF if the end of file was reached in all files
	if (alleof)
	    return (EOF)
	else
	    return (OK)
end


# FC_FDATA -- Get data for a given column. It returns the data type as
# the function value and the data value in one of the function parameters.

int procedure fc_fdata (fptr, fnum, cnum, warnings,
			 ival, rval, dval, strval, maxch)

pointer	fptr			# file structure pointer
int	fnum			# file number
int	cnum			# column number
bool	warnings		# print warnings ?
int	ival			# integer value (output)
real	rval			# real value (output)
double	dval			# double value (output)
char	strval[maxch]		# string value (output)
int	maxch			# maximum number of characters is string

int	dtype
pointer	fsptr, dsptr

begin
#call eprintf ("fc_fdata: fptr=%x, fnum=%d, cnum=%d, warn=%b\n")
#call pargi (fptr)
#call pargi (fnum)
#call pargi (cnum)
#call pargb (warnings)

	# Initialize all output values
	ival = INDEFI
	rval = INDEFR
	dval = INDEFD
	call strcpy ("", strval, maxch)
	dtype = INDEFI

	# Check if file number is in range
	if (fnum <= FS_NFILES (fptr)) {

	    # Get file sub-structure pointer
	    fsptr = FS_FSTRUCTS (fptr)

	    # Check if the column number is in range
	    if (cnum <= FSS_NCOLS (fsptr, fnum)) {

		dsptr = FSS_DATA (fsptr, fnum)

	        dtype = DSS_TYPE (dsptr, cnum)

		switch (dtype) {
		case TY_INT:
		    ival = DSS_IVAL (dsptr, cnum)
		case TY_REAL:
		    rval = DSS_RVAL (dsptr, cnum)
		case TY_DOUBLE:
		    rval = DSS_DVAL (dsptr, cnum)
		case TY_CHAR:
		    call strcpy (DSS_STRVAL (dsptr, cnum), strval, maxch)
		default:
		    call error (0, "fc_fdata: Unknown data type")
		}
	    } else {
		if (warnings) {
		    call eprintf ("Reference to non-existent column %d for file %d at line %d\n")
			call pargi (cnum)
			call pargi (fnum)
			call pargi (FSS_NLINES (fsptr, fnum))
		}
	    }
	} else {
	    if (warnings) {
		call eprintf ("Reference to non-existent file #%d\n")
		    call pargi (fnum)
	    }
	}

	# Return data type
	return (dtype)
end


# FC_FDUMP -- Dump file structures to the standard error.

procedure fc_fdump (fptr)

pointer	fptr			# pointer to file structures

int	i, j
pointer	fsptr, dsptr

begin
	call eprintf ("-- File structure dump (%x) --\n")
	    call pargi (fptr)

	# Return inmediately if the file strcuture pointer is NULL
	if (fptr == NULL) {
	    call eprintf ("Null pointer\n")
	    return
	}

	# Dump structure
	call eprintf ("nfiles=%d, size=%d, structs=%x\n")
	    call pargi (FS_NFILES   (fptr))
	    call pargi (FS_SIZE     (fptr))
	    call pargi (FS_FSTRUCTS (fptr))

	# Dump file sub-structures for all files
	do i = 1, FS_NFILES (fptr) {

	    # Get file sub-structure pointer
	    fsptr = FS_FSTRUCTS (fptr, i)

	    # Dump file sub-structure
	    call eprintf (
		"%2d: fd=%d, ncols=%d, maxcols=%d, colmin=%x, colmax=%x\n")
		call pargi (i)
		call pargi (FSS_FD     (fsptr, i))
		call pargi (FSS_NCOLS  (fsptr, i))
		call pargi (FSS_MAXCOL (fsptr, i))
		call pargi (FSS_COLMIN (fsptr, i))
		call pargi (FSS_COLMAX (fsptr, i))

	    call eprintf ("    avg=%x, median=%x, mode=%x, sigma=%x\n")
		call pargi (FSS_COLAVG    (fsptr, i))
		call pargi (FSS_COLMEDIAN (fsptr, i))
		call pargi (FSS_COLMODE   (fsptr, i))
		call pargi (FSS_COLSIGMA  (fsptr, i))

	    call eprintf ("    data buffer %x: ")
	        call pargi (FSS_DATA (fsptr, i))

	    # Get data sub-structure pointer
	    dsptr = FSS_DATA (fsptr, i)
	    if (dsptr == NULL) {
		call eprintf ("Null buffer\n")
		next
	    }

	    # Dump data sub-structure
	    do j = 1, FSS_NCOLS (fsptr, i) {
		switch (DSS_TYPE (dsptr, j)) {
		case TY_INT:
		    call eprintf ("[i=%d] ")
			call pargi (DSS_IVAL (dsptr, j))
		case TY_REAL:
		    call eprintf ("[r=%g] ")
			call pargr (DSS_RVAL (dsptr, j))
		case TY_DOUBLE:
		    call eprintf ("[d=%g] ")
			call pargd (DSS_DVAL (dsptr, j))
		case TY_CHAR:
		    call eprintf ("[s=%s] ")
			call pargstr (DSS_STRVAL (dsptr, j))
		default:
		    call eprintf ("[?=?] ")
		}
	    }
	    call eprintf ("\n")
	}

	call eprintf ("-- -- -- -- -- -- -- -- --\n")
end
