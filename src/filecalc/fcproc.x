include	<error.h>
include	<lexnum.h>
include	"filecalc.h"

# Abort label
define	abort		99

# Comment character in input lines.
define	COMMENT		"#"

# Structure used to call the formatted output procedure
define	LEN_STRUCT	4		# structure length
define	FC_FPTR		Memi[$1+0]	# file structure pointer
define	FC_CODE		Memi[$1+1]	# code pointer
define	FC_CALCTYPE	Memi[$1+2]	# warnings flag
define	FC_WARNINGS	Memb[$1+3]	# warnings flag


# FC_PROC -- Process input files.

procedure fc_proc (files, ranges, format, calctype, warnings)

char	files[ARB]		# input file list
int	ranges[3, MAX_RANGES]	# line range array
char	format[ARB]		# format string
int	calctype		# calculation type
bool	warnings		# output warnings ?

int	fd
int	ip, one
int	n, nfiles, nexp, dummy
pointer	flist
pointer	sp, fname
pointer	fptr, sptr

int	fntlenb(), fntgfnb()
int	open()
int	strlen()
int	fc_fgetlines(), fc_ccount()
int	fmt_printf()
pointer	fntopnb()
pointer	fc_falloc(), fc_cgetcode()
extern	fc_user()

begin
#call eprintf ("fc_proc: files=(%s), format=(%s), calctype=%d, warnings=%b\n")
#call pargstr (files)
#call pargstr (format)
#call pargi (calctype)
#call pargb (warnings)

	# Open input file list
	flist = fntopnb (files, NO)

	# If the file list is empty return inmediately
	nfiles = fntlenb (flist)
	if (nfiles == 0)
	    return

	# Allocate file structure
	fptr = fc_falloc (nfiles)

	# Allocate memory
	call smark  (sp)
	call salloc (fname, SZ_FNAME,   TY_CHAR)
	call salloc (sptr,  LEN_STRUCT, TY_STRUCT)

	# Initialize structure used for formatted output
	FC_FPTR     (sptr) = fptr
	FC_CALCTYPE (sptr) = calctype
	FC_WARNINGS (sptr) = warnings

	# Open all files and store the file descriptors in
	# the file structure. If a file cannot be opened
	# then free the file structure and raise an error.
	do n = 1, nfiles {

	    # Get next file name
	    dummy = fntgfnb (flist, Memc[fname], SZ_FNAME)

	    # Open input file and store file descriptor and file
	    # name in the file structure.
	    iferr (fd = open (Memc[fname], READ_ONLY, TEXT_FILE)) {
		call fc_ffree (fptr)
		call sfree (sp)
		call erract (EA_ERROR)
	    } else
		call fc_fputfile (fptr, fd, Memc[fname])
	}

	# Close file list
	call fntclsb (flist)

	# Process global column references
	# TO DO

	# Get number of code generation buffers (expressions)
	nexp = fc_ccount ()

	# Loop over all input lines in all files
	while (fc_fgetlines (fptr, ranges, warnings) != EOF) {

	    # Debug
	    # call fc_fdump (fptr)

	    # Set index to the first character in the format string
	    ip = 1

	    # Evaluate all expressions for the input lines. A default value
	    # of the format string is used if no format string is specified
	    do n = 1, nexp {

		# Set code pointer in the user structure
		FC_CODE (sptr) = fc_cgetcode (n)

		# Evaluate the expression
		if (strlen (format[ip]) == 0) {
		    one = 1
		    iferr (
			dummy = fmt_printf (" %g", one, fc_user, sptr)) {
			call erract (EA_WARN)
			goto abort
		    }
		} else {
		    iferr (
			dummy = fmt_printf (format, ip, fc_user, sptr)) {
			call erract (EA_WARN)
			goto abort
		    }
		}
	    }
	    call printf ("\n")
	    call flush  (STDOUT)
	}

abort
	# Free memory
	call fc_ffree (fptr)
	call sfree (sp)
end


# FC_USER -- User supplied procedure template for fm_fprintf().

procedure fc_user (dtype, bval, cval, lval, dval, xval, strval, maxch, ptr)

int	dtype			# data type requested
bool	bval			# boolean value (output)
char	cval			# character value (output)
long	lval			# integer/long value (output)
double	dval			# real/double value (output)
complex	xval			# complex value (output)
char	strval[maxch]		# string value (output)
int	maxch			# max number of characters in string value
pointer	ptr			# pointer to user defined structure

real	fc_evalr()
double	fc_evald()

begin
	# Evaluate according to calculation type
	switch (FC_CALCTYPE (ptr)) {
	case  CALC_REAL:
	    dval = fc_evalr (FC_CODE (ptr), FC_FPTR (ptr), FC_WARNINGS (ptr))
	case  CALC_DOUBLE:
	    dval = fc_evald (FC_CODE (ptr), FC_FPTR (ptr), FC_WARNINGS (ptr))
	default:
	    call error (0, "fc_user: Unknwon calculation type")
	}

	# Branch on data type
	switch (dtype) {
	case TY_BOOL:
	    call error (0, "Attempt to print with boolean format")
	case TY_CHAR:
	    call error (0, "Attempt to print with character or string format")
	case TY_LONG:
	    lval = long (dval)
	case TY_DOUBLE:
	    # dval already computed
	case TY_COMPLEX:
	    call error (0, "Attempt to print with complex format")
	default:
	}
end
