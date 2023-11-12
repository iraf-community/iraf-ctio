include	<error.h>
include	<math/iminterp.h>

# Pointer Mem
define	MEMP		Memi

# Wavelength and width structure
define	LEN_STRUCT	3			        # structure length
define	MAG_SIZE	Memi[$1+0]		        # size (allocated)
define	MAG_COUNT	Memi[$1+1]		        # number of elements
define	MAG_BUFF	MEMP[$1+2]		        # pointer to data buffer

# Individual access
define	MAG_LAMBDA	Memr[MAG_BUFF($1)+2*($2-1)]	# wavelength
define	MAG_WIDTH	Memr[MAG_BUFF($1)+2*($2-1)+1]	# width

# Data buffer size increment
define	INC_SIZE	50

# Output formats
define	FORMATS		"|wide|long|"
define	FORM_WIDE	1
define	FORM_LONG	2

# Output format strings for long output
define	FORM_LNAME	"%s"				# image name
define	FORM_LLAMBDA	"%10.f "			# wavelength
define	FORM_LWIDTH	"%10.f "			# width
define	FORM_LMAG	"%10.f "			# magnitude
define	FORM_LFLUX	"%10.g "			# flux

# Output format strings for wide output
define	FORM_WNAME	"%-10.10s "			# image name
define	FORM_WLAMBDA	"%10.0f "			# wavelength
define	FORM_WWIDTH	"%10.0f "			# width
define	FORM_WMAG	"%10.3f "			# magnitude
define	FORM_WFLUX	"%10.4g "			# flux

# Interpolation modes
define	INTERP_MODES	"|nearest|linear|poly3|poly5|spline3|standard|"
define	MODE_NEAREST	1
define	MODE_LINEAR	2
define	MODE_POLY3	3
define	MODE_POLY5	4
define	MODE_SPLINE3	5
define	MODE_STANDARD	6


# T_MAGBAND - Compute the magnitude for a set of bandpasses. The bandpasses
# are read from a file, and run over a list of spectra. Bandpasses that are
# outside from the spectra wavelength range are discarded, and an INDEF value
# is assigned instead.

procedure t_magband ()

bool	fnu			# convert to fnu ?
bool	fluxflag		# output flux instead of magnitudes ?
bool	convert			# convert wavelengths into angstroms ?
char	input[SZ_FNAME]		# input image name
char	table[SZ_FNAME]		# table file name
char	output[SZ_FNAME]	# output file name
char	w0key[SZ_LINE]		# starting wavelength keyword
char	wpckey[SZ_LINE]		# wavelength increment keyword
char	aux[SZ_LINE]
int	inlist			# input list
int	format			# output format
int	fd			# output file descriptor
int	mode			# interpolation mode
int	npix			# image length
int	i
real	fnuzero			# flux zero point
real	w0, wpc			# wavelength parameters
real	l0, l1			# starting and ending wavelengths
real	x0, x1			# starting and ending pixels
real	flux, flxmag		# flux and magnitude
pointer	asi			# interpolant descriptor
pointer	tbuf			# table buffer
pointer	im			# input image descriptor
pointer	pixels			# image pixel buffer
pointer	sp

bool	clgetb()
int	clgwrd()
int	clpopnu(), clplen(), clgfil()
int	open()
int	imgeti()
real	clgetr()
real	imgetr()
real	asigrl()
real	add_flux()
pointer	immap(), imgl1r()

begin
	# Get parameters
	inlist = clpopnu ("spectra")
	call clgstr ("table", table, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)
	fnu      = clgetb ("fnu")
	fluxflag = clgetb ("flux")
	convert  = clgetb ("convert")
	fnuzero  = clgetr ("fnuzero")
	format   = clgwrd ("format", aux, SZ_LINE, FORMATS)
	call clgstr ("start", w0key, SZ_LINE)
	call clgstr ("delta", wpckey, SZ_LINE)

	# Map interpolation mode into image interpolation modes
	switch (clgwrd ("interpolation", aux, SZ_LINE, INTERP_MODES)) {
	case MODE_NEAREST:
	    mode = II_NEAREST
	case MODE_LINEAR:
	    mode = II_LINEAR
	case MODE_POLY3:
	    mode = II_POLY3
	case MODE_POLY5:
	    mode = II_POLY5
	case MODE_SPLINE3:
	    mode = II_SPLINE3
	case MODE_STANDARD:
	    mode = MODE_STANDARD
	default:
	    call error (0, "Illegal interpolation mode")
	}

	# Read in table
	call mag_table (table, tbuf)

	# Open output file
	fd = open (output, NEW_FILE, TEXT_FILE)

	# Print title if there are images in the
	# list, and if the wide format was selected
	if (clplen (inlist) > 0 && format == FORM_WIDE)
	    call mag_title (fd, tbuf)

	# Initialize image interpolator
	if (mode != MODE_STANDARD)
	    call asiinit (asi, mode)

	# Loop over input spectra
	while (clgfil (inlist, input, SZ_FNAME) != EOF) {

	    # Try to open image
	    iferr (im = immap (input, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Test image dimension
	    if (imgeti (im, "i_naxis") > 1) {
		call eprintf ("More than one dimension in %s\n")
		    call pargstr (input)
		call imunmap (im)
		next
	    }

	    # Get wavelength parameters from the header
	    iferr {
		w0 = imgetr (im, w0key)
		wpc = imgetr (im, wpckey)
	    } then {
		call erract (EA_WARN)
		call imunmap (im)
		next
	    }

	    # Convert wavelength parameters to Angstroms
	    # if they are in meters
	    if (w0 < 1.0 && convert) {
		w0 = w0 * 1E+10
		wpc = wpc * 1E+10
	    }

	    # Get image length
	    npix = imgeti (im, "i_naxis1")

	    # Allocate buffer for image pixels, and read them from the
	    # image. The IMIO buffer can't be used since it may change.
	    call smark  (sp)
	    call salloc (pixels, npix, TY_REAL)
	    call amovr  (Memr[imgl1r (im)], Memr[pixels], npix)

	    # Convert to f-nu if the spectrum is in f-lambda
	    if (!fnu)
	        call confnu (Memr[pixels], w0, wpc, npix)

	    # Interpolate image line
	    if (mode != MODE_STANDARD)
	        call asifit (asi, Memr[pixels], npix)

	    # Output image name to output file. Use all characters
	    # in the name in long format.
	    if (format == FORM_LONG) {
		call fprintf (fd, "\n#")
		call fprintf (fd, FORM_LNAME)
		    call pargstr (input)
		call fprintf (fd, "\n")
	    } else {
		call fprintf (fd, FORM_WNAME)
		    call pargstr (input)
	    }

	    # Loop over all ranges in the table
	    do i = 1, MAG_COUNT (tbuf) {
		
		# Compute wavelength range and check it
		l0 = MAG_LAMBDA (tbuf, i) - MAG_WIDTH (tbuf, i) / 2
		l1 = MAG_LAMBDA (tbuf, i) + MAG_WIDTH (tbuf, i) / 2
		if (l0 < w0 || l1 > w0 + (npix - 1) * wpc) {
		    if (format == FORM_WIDE) {
			if (fluxflag)
		            call fprintf (fd, FORM_WFLUX)
			else
		            call fprintf (fd, FORM_WMAG)
			call pargr (INDEFR)
		    }
		    next
		}

		# Compute starting and ending pixel positions.
		if (mode == MODE_STANDARD) {
		    x0 = (l0 - (w0 - wpc / 2.0)) / wpc
		    x1 = (l1 - (w0 - wpc / 2.0)) / wpc
		} else {
		    x0 = (l0 - w0) / wpc + 1
		    x1 = (l1 - w0) / wpc + 1
		}

		# Compute the integral over the pixel interval,
		# and convert it to magnitudes if necessary
		if (mode != MODE_STANDARD)
		    flux = asigrl (asi, x0, x1) / abs (x0 - x1)
		else
		    flux = add_flux (Memr[pixels], npix, x0, x1) / abs (x0 - x1)

#call eprintf ("x0=%g, x1=%g, l0=%g, l1=%g, flux=%g\n")
#call pargr (x0)
#call pargr (x1)
#call pargr (l0)
#call pargr (l1)
#call pargr (flux)

		# Compute flux or magnitude. Check for zero flux
		# before computing the magnitude.
		if (fluxflag)
		    flxmag = flux
		else {
		    if (flux != 0)
		        flxmag = - 2.5 * log10 (flux / fnuzero)
		    else
			flxmag = INDEFR
		}

		# Write magnitude to output file
		if (format == FORM_WIDE) {
		    if (fluxflag)
			call fprintf (fd, FORM_WFLUX)
		    else
			call fprintf (fd, FORM_WMAG)
		        call pargr (flxmag)
		} else {
		    call fprintf (fd, FORM_LLAMBDA)
			call pargr (MAG_LAMBDA (tbuf, i))
		    if (fluxflag)
			call fprintf (fd, FORM_LFLUX)
		    else
			call fprintf (fd, FORM_LMAG)
		        call pargr (flxmag)
		    call fprintf (fd, FORM_LWIDTH)
			call pargr (MAG_WIDTH (tbuf, i))
		    call fprintf (fd, "\n")
		}
	    }

	    # Free pixel memory
	    call sfree (sp)

	    # Skip two lines if in wide format
	    if (format == FORM_WIDE)
	        call fprintf (fd, "\n\n")

	    # Close image
	    call imunmap (im)
	}

	# Free space and close all
	if (mode != MODE_STANDARD)
	    call asifree (asi)
	call close (fd)
	call clpcls (inlist)
end


# MAG_TABLE - Read table and store it into a structure in memory

procedure mag_table (name, ptr)

char	name[ARB]		# table name
pointer	ptr			# table pointer (output)

int	fd			# file descriptor
real	lambda, width		# wavelength and width

int	open(), fscan(), nscan()

begin
	# Open table file and scan it
	fd = open (name, READ_ONLY, TEXT_FILE)

	# Allocate table buffer
	call malloc (ptr, LEN_STRUCT, TY_STRUCT)
	call malloc (MAG_BUFF (ptr), INC_SIZE, TY_REAL)
	MAG_SIZE (ptr) = INC_SIZE
	MAG_COUNT (ptr) = 0

	# Loop over table file
	while (fscan (fd) != EOF) {

	    # Read wavelength and width
	    call gargr (lambda)
	    call gargr (width)
	    if (nscan () != 2)
		call error (0, "Bad table format")

	    # Test for zero width
	    if (width == 0)
		call error (0, "Zero box width in table")

	    # Increment counter
	    MAG_COUNT (ptr) = MAG_COUNT (ptr) + 1

	    # Reallocate space if necessary
	    if (2 * MAG_COUNT (ptr) > MAG_SIZE (ptr)) {
		MAG_SIZE (ptr) = MAG_SIZE (ptr) + INC_SIZE
		call realloc (MAG_BUFF (ptr), MAG_SIZE (ptr), TY_REAL)
	    }

	    # Insert data into the structure
	    MAG_LAMBDA (ptr, MAG_COUNT (ptr)) = lambda
	    MAG_WIDTH  (ptr, MAG_COUNT (ptr)) = width
	}

	# Close file
	call close (fd)
end


# MAG_TITLE - Write title line

procedure mag_title (fd, ptr)

int	fd			# output file descriptor
pointer	ptr			# table pointer (output)

int	i

begin
	# Print wavelengths
	call fprintf (fd, FORM_WNAME)
	    call pargstr ("# Wavelen.")
	do i = 1, MAG_COUNT (ptr) {
	    call fprintf (fd, FORM_WLAMBDA)
		call pargr (MAG_LAMBDA (ptr, i))
	}

	# Skip one line
	call fprintf (fd, "\n")

	# Print bandpass widths
	call fprintf (fd, FORM_WNAME)
	    call pargstr ("# Width")
	do i = 1, MAG_COUNT (ptr) {
	    call fprintf (fd, FORM_WWIDTH)
		call pargr (MAG_WIDTH (ptr, i))
	}

	# Skip two lines
	call fprintf (fd, "\n\n")
end
