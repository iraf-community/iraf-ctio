include	<error.h>
include	<mach.h>
include	<math/iminterp.h>

# Speed of light in kilometers/second
define	LIGHT_SPEED	2.9979E5

# Table size parameters
define	TABLE_SIZE	100				# Initial size
define	TABLE_INC	50				# Size increment

# Pointer Mem
define	MEMP		Memi

# Bandpass access
define	LEN_BANDS	7			        # structure unit length
define	EQW_REDL	Memr[$1+0+($2-1)*LEN_BANDS]	# red wavelength
define	EQW_REDW	Memr[$1+1+($2-1)*LEN_BANDS]	# red width
define	EQW_BLUEL	Memr[$1+2+($2-1)*LEN_BANDS]	# blue wavelength
define	EQW_BLUEW	Memr[$1+3+($2-1)*LEN_BANDS]	# blue width
define	EQW_LINEL	Memr[$1+4+($2-1)*LEN_BANDS]	# line wavelength
define	EQW_LINEW	Memr[$1+5+($2-1)*LEN_BANDS]	# line width
define	EQW_COMMAND	Memi[$1+6+($2-1)*LEN_BANDS]	# band command (future)

# Radial correction access
define	EQW_RADIAL	Memr[$1+$2-1]			# factor

# Interpolation modes
define	INTERP_MODES	"|nearest|linear|poly3|poly5|spline3|"
define	MODE_NEAREST	1
define	MODE_LINEAR	2
define	MODE_POLY3	3
define	MODE_POLY5	4
define	MODE_SPLINE3	5

# Output formats
#define	FORM_TITLE	"# %9.9s  %9.9s  %9.9s  %9.9s  %9.9s  %9.9s\n"
#define	FORM_DATA	"  %9.2f  %9.2f  %9.2f  %9.2f  %9.2f  %9.2f\n"
define	FORM_TITLE	"# %9.9s  %9.9s  %9.9s  %9.9s  %9.9s  %11.11s\n"
define	FORM_DATA	"  %9.2f  %9.2f  %9.2f  %9.2f  %9.2f  %11.4f\n"


# T_EQWIDTHS -- Compute the equivalent widths for a list of input spectra.
# A list of bandpasses is supplied in a text file, and all of them are applied
# to each spectrum in the list. A list of radial velocities may optionally be
# specified to apply to each spectrum in the list. If the list of radial
# velocities is shorter than the list of images, then no corrrection is
# applied to the remaining spectra in the list. The output is written to
# an output file in multicolumn format.

procedure t_eqwidths ()

bool	fcflag			# flux calibrated ?
char	input[SZ_FNAME]		# input image name
char	bands[SZ_FNAME]		# band file name
char	radial[SZ_FNAME]	# radial velocity file name
char	output[SZ_FNAME]	# output file name
char	w0key[SZ_LINE]		# starting wavelength keyword
char	wpckey[SZ_LINE]		# wavelength increment keyword
char	dckey[SZ_LINE]		# dispersion correction flag keyword
char	fckey[SZ_LINE]		# flux calibration flag keyword
char	aux[SZ_LINE]
int	inlist			# input list
int	nimages			# image counter
int	bt			# band table pointer
int	rt			# radial velocity table pointer
int	fd			# output file descriptor
int	nband			# number of band specifications
int	nrad			# number of radial correction specifications
int	mode			# interpolation mode
int	dummy
real	w0, wpc			# wavelength parameters
real	rvcorr			# radial velocity correction factor
pointer	im			# input image descriptor

int	clgwrd()
int	clpopnu(), clgfil()
int	open()
int	imgeti()
real	imgetr()
pointer	immap()

begin
	# Get file names
	inlist = clpopnu ("spectra")
	call clgstr ("bands", bands, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)
	call clgstr ("radial", radial, SZ_FNAME)

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
	default:
	    call error (0, "Illegal interpolation mode")
	}

	# Get keyword names
	call clgstr ("start", w0key, SZ_LINE)
	call clgstr ("delta", wpckey, SZ_LINE)
	call clgstr ("dispersion", dckey, SZ_LINE)
	call clgstr ("flux", fckey, SZ_LINE)

	# Open output file
	fd = open (output, NEW_FILE, TEXT_FILE)

	# Read bands into memory
	call eqw_bands (bands, bt, nband)

	# Read radial velocity factors
	call eqw_radial (radial, rt, nrad)

	# Loop over input spectra
	nimages = 0
	while (clgfil (inlist, input, SZ_FNAME) != EOF) {

	    # Count images
	    nimages = nimages + 1

	    # Open input image
	    iferr (im = immap (input, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Test image dimension, and process it
	    if (imgeti (im, "naxis") > 1) {
		call eprintf ("More than one dimension in %s\n")
		    call pargstr (input)
		call imunmap (im)
		next
	    }

	    # Get wavelength parameters from the header
	    iferr {
		w0 = imgetr (im, w0key)
		wpc = imgetr (im, wpckey)
		dummy = imgeti (im, dckey)
	    } then {
		call erract (EA_WARN)
		call imunmap (im)
		next
	    }

	    # Get flux calibration flag
	    iferr (dummy = imgeti (im, fckey))
		fcflag = false
	    else
		fcflag = true

	    # Get radial velocity correction
	    if (rt != NULL) {
		if (nimages <= nrad)
		    rvcorr = EQW_RADIAL (rt, nimages)
		else
		    rvcorr = 1.0
	    } else
		rvcorr = 1.0

	    # Print image name into output file
	    call fprintf (fd, "\n# %s (%s)\n")
		call pargstr (input)
	    if (fcflag)
		call pargstr ("flux calibrated")
	    else
		call pargstr ("not flux calibrated")
	    call fprintf (fd, FORM_TITLE)
		call pargstr ("center")
		call pargstr ("width")
		call pargstr ("lab.")
		call pargstr ("line flux")
		call pargstr ("continuum")
		call pargstr ("eq. width")

	    # Process image
	    call eqw_proc (im, bt, nband, rt, nrad, w0, wpc,
			   rvcorr, fcflag, mode, fd)

	    # Close image
	    call imunmap (im)
	}

	# Close all
	call close (fd)
	if (nrad != 0)
	    call mfree (rt, TY_REAL)
	call mfree (bt, TY_REAL)
	call clpcls (inlist)
end


# EQW_PROC -- Compute the equivalent with of a list of bandpasses for a
# single image. If the bandpasses are out of the spectrum range then INDEF
# results are written into the output file.

procedure eqw_proc (im, bt, nband, rt, nrad, w0, wpc, rvcorr, fcflag,
			 mode, fd)

pointer	im			# image descriptor
pointer	bt			# bandpass table pointer
int	nband			# number of bandpasses
pointer	rt			# radial velocity table pointer
real	w0			# starting wavelength
real	wpc			# wavelength increment
bool	fcflag			# flux calibration flag
real	rvcorr			# radial velocity correction
int	nrad			# number of radial velocity corrections
int	mode			# interpolation mode
int	fd			# output file descriptor

int	i, j
int	npix			# spectrum length
real	redlambda, redwidth, redflux
real	bluelambda, bluewidth, blueflux
real	linelambda, linewidth, lineflux
real	linelab
real	eqwidth			# equivalent width
real	contval			# continuum value
real	a, b			# linear interpolation parameters
pointer	pixels			# spectrum
pointer	continuum		# continuum
pointer	asi			# interpolator descriptor
pointer	sp, temp

int	imgeti()
real	eqw_flux()
pointer	imgl1r()

begin
	# Get image length
	npix = imgeti (im, "naxis1")

	# Allocate buffer for image pixels, continuum,
	# and working space
	call smark (sp)
	call salloc (pixels, npix, TY_REAL)
	call salloc (continuum, npix, TY_REAL)
	call salloc (temp, npix, TY_REAL)

	# Move image pixels to temporary buffer. This is necessary
	# since the image buffer is modified in the program.
	call amovr (Memr[imgl1r (im)], Memr[pixels], npix)

	# Initialize image interpolation
	call asiinit (asi, mode)

	# Loop over all bandpasses
	do i = 1, nband {

	    # Interpolate image line
	    call asifit (asi, Memr[pixels], npix)

	    # Get bandpass
	    redlambda  = EQW_REDL  (bt, i)
	    redwidth   = EQW_REDW  (bt, i)
	    bluelambda = EQW_BLUEL (bt, i)
	    bluewidth  = EQW_BLUEW (bt, i)
	    linelambda = EQW_LINEL (bt, i)
	    linewidth  = EQW_LINEW (bt, i)

	    # Apply radial velocity corrections to wavelengths
	    redlambda  = redlambda  * rvcorr
	    bluelambda = bluelambda * rvcorr
	    linelab    = linelambda * rvcorr

	    # Compute red and blue fluxes per unit
	    redflux  = eqw_flux (asi, redlambda, redwidth, w0, wpc, npix,
				 false)
	    blueflux = eqw_flux (asi, bluelambda, bluewidth, w0, wpc, npix,
				 false)

	    # Continue with computations only if the red and blue
	    # fluxes are both defined
	    if (!IS_INDEFR (redflux) && !IS_INDEFR (blueflux)) {

		# Compute coefficients for continuum interpolation,
		# and evaluate the continuum for the line
		a = (redflux - blueflux) / (redlambda - bluelambda)
		b = redflux - a * redlambda
		do j = 1, npix 
		    Memr[continuum + j - 1] = a * (w0 + (j - 1) * wpc) + b

		# Substract the continuum from the spectrum and compute the
		# line flux for the resultant spectrum
		#call asubr (Memr[pixels], Memr[continuum], Memr[temp], npix)
		#call aabsr (Memr[temp], Memr[temp], npix)

		# Substract the spectrum from the continuum and compute the
		# line flux for the resultant spectrum
		call asubr (Memr[continuum], Memr[pixels], Memr[temp], npix)
		call asifit (asi, Memr[temp], npix)
		lineflux = eqw_flux (asi, linelab, linewidth, w0, wpc,
				     npix, true)

		# Correct flux if the spectrum is flux calibrated
		if (fcflag)
		    lineflux = lineflux * wpc

		# Compute equivalent with. The equivalent will be always
		# positive for absorption lines and negative for emission
		# lines, unless (one or both) the fluxes in the red and
		# blue bandpasses are negative.
		if (a * linelab + b != 0)
		    eqwidth = lineflux / (a * linelab + b)
		else
		    eqwidth = INDEFR

		# Compute continuum level
		contval = Memr[continuum + int ((linelab - w0) / wpc)]

	    } else {
		lineflux = INDEFR
		eqwidth  = INDEFR
		contval  = INDEFR
	    }

	    # Print results
	    call fprintf (fd, FORM_DATA)
		call pargr (linelambda)
		call pargr (linewidth)
		call pargr (linelab)
		call pargr (lineflux)
		call pargr (contval)
		call pargr (eqwidth)
	}

	# Flush output on every image
	call flush (fd)

	# Free memory
	call asifree (asi)
	call sfree (sp)
end


# EQW_FLUX - Compute the total flux for a given wavelength interval. Check
# for wavelength range before doing the integration. Return INDEF if the
# band limits are out of the spectrum limits.

real procedure eqw_flux (asi, lambda, width, w0, wpc, npix, total)

pointer	asi			# interpolant descriptor
real	lambda			# interval wavelength
real	width			# interval width
real	w0			# starting wavlength
real	wpc			# wavelength increment
int	npix			# spectrum length
bool	total			# return total flux ?

real	l0, l1
real	x0, x1

real	asigrl()

begin
	# Compute starting, and ending wavelength, 
	# and check for range.
	l0 = lambda - width / 2
	l1 = lambda + width / 2
	if (l0 < w0 || l1 > w0 + (npix - 1) * wpc)
	    return (INDEFR)

	# Compute starting and ending pixel positions
	x0 = max ((l0 - w0 + wpc) / wpc, 1.0)
	x1 = min ((l1 - w0 + wpc) / wpc, real (npix))

	# Return flux
	if (total)
	    return (asigrl (asi, x0, x1))
	else
	    return (asigrl (asi, x0, x1) / abs (x0 - x1))
end


# EQW_BANDS - Read bandpasses from the file, and put them into a table in
# memory. Return the real table pointer, and the number of entries. If the
# file does no exist it raises an error condition.

procedure eqw_bands (bands, bt, nband)

char	bands[ARB]		# bandpass file name
pointer	bt			# bandpass table descriptor (output)
int	nband			# number of bandpasses (output)

char	cmd[1]
int	fd			# file descriptor
int	size
real	rl, rw, bl, bw, ll, lw

int	strlen()
int	open(), fscan(), nscan()
errchk	open()

begin
	# Open file
	fd = open (bands, READ_ONLY, TEXT_FILE)

	# Allocate table
	size = TABLE_SIZE * LEN_BANDS
	call malloc (bt, size, TY_REAL)

	# Loop reading correction factors from file
	nband = 0
	while (fscan (fd) != EOF) {

	    # Read bands
	    call gargr (rl)
	    call gargr (rw)
	    call gargr (ll)
	    call gargr (lw)
	    call gargr (bl)
	    call gargr (bw)

	    # Check sucessfull read
	    if (nscan () != 6) {
		call mfree (bt, TY_REAL)
		call error (0, "Illegal format in bandpass file")
	    }

	    # Read command
	    call gargwrd (cmd, 1)

	    # Check table space
	    nband = nband + 1
	    if (nband * LEN_BANDS > size) {
		size = size + TABLE_INC * LEN_BANDS
		call realloc (bt, size, TY_REAL)
	    }

	    # Enter values into table
	    EQW_REDL  (bt, nband) = rl
	    EQW_REDW  (bt, nband) = rw
	    EQW_LINEL (bt, nband) = ll
	    EQW_LINEW (bt, nband) = lw
	    EQW_BLUEL (bt, nband) = bl
	    EQW_BLUEW (bt, nband) = bw

	    # Enter command into table if there is any
	    if (strlen (cmd) > 0)
		EQW_COMMAND (bt, nband) = cmd[1]
	    else
		EQW_COMMAND (bt, nband) = '\000'
	}

	# Close file
	call close (fd)
end


# EQW_RADIAL - Read radial velocity correction factors from the file, and put
# them into a table in memory. Return the real table pointer, and the number of
# entries.

procedure eqw_radial (radial, rt, nrad)

char	radial[ARB]		# radial factor file name
pointer	rt			# radial table descriptor
int	nrad			# total number of factors read

int	fd			# file descriptor
int	size
real	vel

int	strlen()
int	open(), fscan(), nscan()
errchk	open()

begin
	# If no file name is specified return null table
	# pointer and zero table entries
	if (strlen (radial) == 0) {
	    rt = NULL
	    nrad = 0
	    return
	}

	# Open radial velocity file
	fd = open (radial, READ_ONLY, TEXT_FILE)

	# Allocate table
	size = TABLE_SIZE
	call malloc (rt, size, TY_REAL)

	# Loop reading velocities from file
	nrad = 0
	while (fscan (fd) != EOF) {

	    # Read velocity
	    call gargr (vel)

	    # Check sucessfull read
	    if (nscan () != 1) {
		call mfree (rt, TY_REAL)
		call error (0, "Illegal format in radial velocity file")
	    }

	    # Check table space
	    nrad = nrad + 1
	    if (nrad > size) {
		size = size + TABLE_INC
		call realloc (rt, size, TY_REAL)
	    }

	    # Compute the actual factor and store it into the table
	    EQW_RADIAL (rt, nrad) =  sqrt ((LIGHT_SPEED + vel) /
					   (LIGHT_SPEED - vel))
	}

	# Close file
	call close (fd)
end
