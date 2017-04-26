include	<error.h>
include	<mach.h>
include	<math/curfit.h>

# Function types
define	FUNC_CHEBYSHEV		"chebyshev"
define	FUNC_LEGENDRE		"legendre"
define	FUNC_SPLINE3		"spline3"
define	FUNC_SPLINE1		"spline1"

# Keyword values
define	KEY_ORDER		"order"
define	KEY_FUNCTION		"function"
define	KEY_COEFF		"coefficent"


# CEV_PROC -- Read the CURFIT input if the minimum value (xmin) is greater
# or equal than the maximum value supplied. Otherwise use them as limit
# values.  Then initialize the curve fitting descriptor, and evaluate the
# fit for all the data points in the input file.

procedure cev_procr (input, curfin, curfout, xmin, xmax)

char	input[ARB]		# input file
char	curfin[ARB]		# CURFIT input file
char	curfout[ARB]		# CURFIT output file
real	xmin, xmax		# limit values for CURFIT input (if specified)

int	func			# function type
int	ncoeffs			# number of coefficients
pointer	cv			# curve descriptor
pointer	coeff			# coefficient buffer

begin
	# Read in CURFIT output
	call cev_curfoutr (curfout, func, coeff, ncoeffs)

	# Determine minimum and maximum values from the input
	# data to CURFIT, if the minimum supplied value is 
	# greater or equal to the maximim supplied value.
	# Otherwise use the supplied values.
	if (xmin >= xmax) {
	    iferr (call cev_minmaxr (curfin, xmin, xmax)) {
		call mfree (coeff, TY_REAL)
		call erract (EA_ERROR)
	    }
	}

	# Initialize curve descriptor with coefficient values
	call cvset (cv, func, xmin, xmax, Memr[coeff], ncoeffs)

	# Evaluate the fit
	iferr (call cev_evalr (input, cv)) {
	    call mfree (coeff, TY_REAL)
	    call erract (EA_ERROR)
	}

	# Free curve descriptor
	call cvfree (cv)

	# Free coefficient buffer
	call mfree (coeff, TY_REAL)
end


# CEV_CURFOUT -- Read in the output from the CURFIT task. It returns the
# function type, a buffer with the coefficient values, and the number of
# coefficients. The buffer is allocated in the procedure.

procedure cev_curfoutr (fname, func, coeff, ncoeffs)

char	fname[ARB]		# file name
int	func			# function type (output)
pointer	coeff			# coefficient buffer (output)
int	ncoeffs			# number of coefficients (output)

bool	fcoeffs
int	fd
int	i, ip
pointer	sp, keyword, dummy, value

bool	streq()
int	ctoi()
int	open(), fscan(), nscan()
errchk	open()

begin
	# Open file
	fd = open (fname, READ_ONLY, TEXT_FILE)

	# Allocate string space
	call smark (sp)
	call salloc (keyword, SZ_LINE, TY_CHAR)
	call salloc (dummy,   SZ_LINE, TY_CHAR)
	call salloc (value,   SZ_LINE, TY_CHAR)

	# Initialize variables
	fcoeffs = false
	ncoeffs = INDEFI

	# Read file
	while (fscan (fd) != EOF) {

	    # Read three tokens from the line. Skip empty lines.
	    call gargwrd (Memc[keyword], SZ_LINE)
	    call gargwrd (Memc[dummy],   SZ_LINE)
	    call gargwrd (Memc[value],   SZ_LINE)
	    if (nscan() < 1)
		next

	    # Take action acording to the keyword value
	    if (streq (Memc[keyword], KEY_ORDER)) {
		ip = 1
		if (ctoi (Memc[value], ip, ncoeffs) < 1)
		    call error (0, "Illegal number of coefficients")
	    } else if (streq (Memc[keyword], KEY_FUNCTION)) {
		if (streq (Memc[value], FUNC_CHEBYSHEV))
		    func = CHEBYSHEV
		else if (streq (Memc[value], FUNC_LEGENDRE))
		    func = LEGENDRE
		else if (streq (Memc[value], FUNC_SPLINE3))
		    func = SPLINE3
		else if (streq (Memc[value], FUNC_SPLINE1))
		    func = SPLINE1
		else
		    call error (0, "Unknown function type")
	    } else if (streq (Memc[keyword], KEY_COEFF)) {
		fcoeffs = true
		break
	    }
	}

	# Read in coefficient values if the start of the coefficient
	# list and the number of coefficients were found in the previous
	# loop. Otherwise raise an error.
	if (fcoeffs && !IS_INDEFI (ncoeffs)) {

	    # Adjust number of coefficients for spline1 and spline3
	    if (func == SPLINE1)
		ncoeffs = ncoeffs + 1
	    else if (func == SPLINE3)
		ncoeffs = ncoeffs + 3

	    # Allocate space for coefficients
	    call malloc (coeff, ncoeffs, TY_REAL)

	    # Read in coefficients
	    do i = 1, ncoeffs {
	        if (fscan (fd) == EOF) {
		    call mfree (coeff, TY_REAL)
	    	    call sfree (sp)
		    call error (0, "EOF before expected")
		} else
		    call gargr (Memr[coeff + i - 1])
	    }

	} else {
	    call sfree (sp)
	    call error (0, "Function order and/or coefficient list missing")
	}

	# Free memory and close file
	call sfree (sp)
	call close (fd)
end


# CEV_MINMAX -- Determine the minimum and maximum values from the input file
# of the CURFIT task. These values are required by the CURFIT library.
# If the input file contains only one column of data, then the minimum values
# is always one and the maximum value is equal to the number of lines in
# the file.

procedure cev_minmaxr (fname, xmin, xmax)

char	fname[ARB]		# file name
real	xmin, xmax		# limit values (output)

int	fd
int	ncols, nlines
real	x, y

int	open(), fscan(), nscan()
errchk	open()

begin
	# Open file
	fd = open (fname, READ_ONLY, TEXT_FILE)

	# Initialize limit values
	xmin = MAX_REAL
	xmax = - MAX_REAL

	# Read file
	nlines = 0
	ncols  = INDEFI
	while (fscan (fd) != EOF) {

	    # Read value skipping empty lines
	    call gargr (x)
	    call gargr (y)
	    if (nscan () < 1)
		next

	    # Determine whether the input has one or two columns.
	    # The test is made on the first non empty line.
	    if (IS_INDEFI (ncols))
		ncols = nscan ()

	    # Skip incomplete lines
	    if (nscan () < ncols)
		next

	    # Determine limits from the data if there are
	    # more than one column, i.e. (x,y) pairs.
	    if (ncols > 1) {
		if (x > xmax)
		    xmax = x
		if (x < xmin)
		    xmin = x
	    }

	    # Count lines
	    nlines = nlines + 1
	}

	# If no lines were read raise an error condition
	if (nlines == 0)
	    call error (0, "No lines in CURFIT input")

	# Set the minimum and maximum values to one and the
	# number of lines, respectively, if the input file had
	# only one column.
	if (ncols == 1) {
	    xmin = real (1)
	    xmax = real (nlines)
	}

	# Close file
	call close (fd)
end


# CEV_EVAL -- Evaluate the fit for input data, and write the data points,
# along with the fit values, to the standard output.

procedure cev_evalr (fname, cv)

char	fname[ARB]		# file name
pointer	cv			# curve descriptor

int	fd
real	value, fit

int	open(), fscan(), nscan()
errchk	open()

real cveval()

begin
	# Open file
	fd = open (fname, READ_ONLY, TEXT_FILE)

	# Read file
	while (fscan (fd) != EOF) {

	    # Read value to evaluate the fit
	    call gargr (value)
	    if (nscan () < 1)
		next

	    # Evaluate the fit and write it to 
	    # the standard output
	    fit = cveval (cv, value)
	    call printf ("%g %g\n")
		call pargr (value)
		call pargr (fit)
	}

	# Close file
	call close (fd)
end
