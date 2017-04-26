include <error.h>

# Maximum size of working box (not usefull in the SPP
# version, but preserved just for ??? )
define	NMAX			3000

# Maximum value of the outer sky radius
define	RMAX			40.0

# Sky determination modes
define	SKYMODES		"|mean|median|mode|sigclip|"
define	SKY_MEAN		1
define	SKY_MEDIAN		2
define	SKY_MODE		3
define	SKY_SIGCLIP		4
define	SKY_LAST		SKY_SIGCLIP

# Errors in magnitude
define	ERR_N			1
define	ERR_SKY			2
define	ERR_NOISE		3
define	ERR_LAST		ERR_NOISE

# Quit option
define	QUIT			'q'


# SPHOT - Star photometry main procedure. Read all the parameters from the
# CL, and loop over all images in the input list.

procedure t_sphot()

bool	sflag			# use star list ?
char	image[SZ_FNAME]		# image name
int	starlist		# star coordinate files
int	imlist			# input image list
pointer	gp			# graphics descriptor

bool	clgetb()
int	clgeti(), clgwrd()
int	clpopnu (), clplen(), clgfil()
real	clgetr()
pointer	gopen()

include	"sphot.com"

begin
	# Open image list
	imlist = clpopnu ("images")

	# Get all hidden parameters
	starlist = clpopnu ("starlist")
	rstar = clgetr ("rstar")
	r1 = clgetr ("r1")
	r2 = clgetr ("r2")
	rdel = clgetr ("rdel")
	niter = clgeti ("niter")
	cside = clgeti ("cside")
	isky = clgwrd ("sky", skymode, SZ_LINE, SKYMODES)
	ksig = clgetr ("ksig")
	zpoint = clgetr ("zpoint")
	gain = clgetr ("gain")
	verbose = clgetb ("verbose")

	# Open standard image only if the star list
	# does not contain any file name, and flag
	# use of star list
	if (clplen (starlist) == 0) {
	    iferr (gp = gopen ("stdimage", APPEND, STDIMAGE))
	        gp = NULL
	    sflag = false
	} else
	    sflag = true

	# Loop over input images
	while (clgfil (imlist, image, SZ_FNAME) != EOF)
	    call sphot (image, starlist, sflag)

	# Close all
	if (gp != NULL)
	    call gclose (gp)
	call clpcls (starlist)
	call clpcls (imlist)
end


# SPHOT - Open the image, open each one of the star positions files and
# run the photometry routine for each star position.

procedure sphot (image, starlist, sflag)

char	image[ARB]		# image name
int	starlist		# star ccordinate file list
bool	sflag			# use list ?

char	line[SZ_LINE]		# input coordinate line
char	stars[SZ_FNAME]		# current star position file name
char	junk[SZ_FNAME]
char	key			# last keystroke
int	fd			# star coordinate file descriptor
int	starnum			# number of the current star being processed
int	filter			# filter number
int	wcs			# WCS (not used)
int	n, ip
real	xi, yi			# initial star position
real	airmass			# air mass
real	exptime			# exposure time
pointer	im			# input image descriptor

int	cctoc(), ctoi(), ctor()
int	clgcur()
int	clgfil()
int	imgeti()
int	open(), fscan()
real	imgetr()
pointer	immap()

include	"sphot.com"

begin
	# Try to open image
	iferr (im = immap (image, READ_ONLY, 0)) {
	    call erract (EA_WARN)
	    return
	}

	# Get exposure time from the image header. If it cannot
	# find ITIME or EXPTIME, assume time = 1 and issue warning.
	iferr (exptime = imgetr (im, "ITIME")) {
	    iferr (exptime = imgetr (im, "EXPTIME")) {
		call eprintf ("no integration or exposure time in header\n")
		exptime = INDEFR
	    }
	}
	if (exptime == 0.0 || IS_INDEFR (exptime)) {
	    exptime = 1.0
	    call eprintf ("exposure time set to 1 second !\n")
	}

	# Get the airmass. If can't find it asume INDEFR value
	iferr (airmass = imgetr (im, "AIRMASS")) {
	    airmass = INDEFR
	}

	# Output the image characteristics at the beginning: image name,
	# title, exposure time, airmass and filter
	call printf ("Image = %s    Title = %s\nExposure time = %6.2f")
	    call pargstr (image)
	    call imgstr (im, "i_title", junk, SZ_LINE)
	    call pargstr (junk)
	    call pargr (exptime)
	if (airmass == INDEFR)
	    call printf ("    Airmass = no data")
	else {
	    call printf ("    Airmass = %6.3f")
	        call pargr (airmass)
	}
	iferr (filter = imgeti (im, "F1POS"))
	    call printf ("    Filter = no data\n")
	else {
	    call printf ("    Filter = %d\n")
		call pargi (filter)
	}

	# Output setup parameters if verbose format set or line title
	# otherwise
	if (verbose) {
	    call printf ("\nSetup parameters:\n")
	    call printf ("radius of stellar aperture          = %6.3f\n")
		call pargr (rstar)
	    call printf ("inner sky radius                    = %6.3f\n")
		call pargr (r1)
	    call printf ("outer sky radius                    = %6.3f\n")
		call pargr (r2)
	    call printf ("maximum shitf from initial position = %6.3f\n")
		call pargr (rdel)
	    call printf ("number of iterations for centroid   = %3d\n")
		call pargi (niter)
	    call printf ("half width of centering box         = %3d\n")
		call pargi (cside)
	    call printf ("sky                                 = %s\n")
		call pargstr (skymode)
	    call printf ("sigma rejection parameter           = %6.3f\n")
		call pargr (ksig)
	    call printf ("magnitude zero point                = %6.3f\n")
		call pargr (zpoint)
	    call printf ("gain (electrons/ADU)                = %6.3f\n")
		call pargr (gain)
	} else
	    call printf ( "star#      x         y       mag   sigmag      sky    sigsky  nsky\n")

	# Decide whether to use the standard cursor or the
	# star position files to get the star coordinates
	if (sflag) {

	    # Reset star counter, rewind the list and read
	    # star coordinates from each file in the list.
	    starnum = 1
	    call clprew (starlist)
	    while (clgfil (starlist, stars, SZ_FNAME) != EOF) {

		# Try to open the star coordinate file. Issue
		# a warning message and continue with the next
		# file if it fails
		iferr (fd = open (stars, READ_ONLY, TEXT_FILE)) {
		    call erract (EA_WARN)
		    next
		}

		# Read file lines, and scan the appropiate
		# information
		while (fscan (fd) != EOF) {

		    # Read line
		    call gargstr (line, SZ_LINE)

		    # Scan the input line for star coordinates,
		    # world coordinate system, and keystroke
		    ip = 1
		    if (ctor (line, ip, xi) == 0)
			xi = INDEFR
		    if (ctor (line, ip, yi) == 0)
			yi = INDEFR
		    n = ctoi (line, ip, wcs)
		    if (cctoc (line, ip, key) == 0)
			key = '\000'

		    # Break the loop of the keystroke was QUIT
		    if (key != QUIT) {
	    	        call sphot1 (im, exptime, xi, yi, starnum)
		    } else
		        break

	            # Count star positions
	            starnum = starnum + 1
		}
	    }

	} else {

	    # Reset star counter, and read star coordinates
	    # from standard cursor
	    starnum = 1
	    while (clgcur ("cursor", xi, yi, wcs, n, junk, SZ_LINE) != EOF) {

		# Convert integer keystroke into
		# a character keystroke
		key = n

		# Break the loop of the keystroke was QUIT
		if (key != QUIT)
		    call sphot1 (im, exptime, xi, yi, starnum)
		else
		    break

	        # Count star positions
	        starnum = starnum + 1
	    }
	}
end


# SPHOT1 - Call the actual photometry routine if the star coordinates have
# legal values

procedure sphot1 (im, exptime, xi, yi, starnum)

pointer	im			# image file descriptor
real	exptime			# exposure time
real	xi, yi			# initial star position
int	starnum			# number of current star

begin
	# Call the photometry routine only if the star coordiantes
	# are defined, and have positive values. Otherwise issue a
	# warning message.
	if (!IS_INDEFR (xi) && !IS_INDEFR (yi) && xi > 0 && yi > 0)
	    call photometry (im, exptime, xi, yi, starnum)
	else {
	    call printf ("Illegal star coordinates: x=%g, y=%g\n")
		call pargr (xi)
		call pargr (yi)
	}
end


# PHOTOMETRY - Photometry procedure. Call the fortran routines "xysetp" and
# "photom". 

procedure photometry (im, exptime, xi, yi, starnum)

pointer	im			# image file descriptor
real	exptime			# exposure time
real	xi, yi			# initial star position
int	starnum			# number of current star (always increasing)

int	nx, ny			# number of rows and colums
int	i1, i2, j1, j2		# boundaries of the box extracted
int	ndata			# total number of points in array
int	nsky			# number of sky pixels
int	nstar			# number of pixels in star aperture
int	ier			# error code returned
real	x, y			# star position
real	sky[SKY_LAST]		# sky (mean, median, mode, sigma clip)
real	sigsky			# sigma sky
real	mag			# star magnitude
real	err[ERR_LAST]		# errors in magnitude (n, sky, noise)
real	sig			# error
real	strsum			# total star counts
pointer bufptr			# pointer to data buffer

int	imgeti()
pointer	imgs2r()

include	"sphot.com"

begin 
	# Check star radii setup
	if (rstar > r1 || r1 >= r2 || r2 >= RMAX) {
	    call eprintf ("error in star/sky radii setup\n")
	    return	
	}

	# Now work out the boundaries of the box to extract
	nx = imgeti (im, "i_naxis1")
	ny = imgeti (im, "i_naxis2")
	call xysetp (xi, yi, rstar, rdel, r2, nx, ny, i1, i2, j1, j2,
		      NMAX, ndata, ier)
	if (ier != 0) {
	    call xyerror (ier, xi, yi)
	    return
	}

	# Extract that box in real format
	bufptr = imgs2r (im, i1, i2, j1, j2)

	# Call the main photometry routine
 	call photom (xi, yi, Memr[bufptr], ndata, i1, i2, j1, j2, rstar, r1, r2,
		     cside, niter, rdel, isky, ksig, zpoint, exptime, gain,
		     x, y, sky, nsky, sigsky, strsum, mag, nstar, err, sig, ier)
	if (ier != 0) {
	    call photerror (ier, xi, yi)
	    return
	}

	# Output
	if (verbose) {
	    call printf ("\nStar # %d:\n")
		call pargi (starnum)
	    call printf ("number of sky pixels              = %d\n")
		call pargi (nsky)
	    call printf ("sky mean                          = %6.3f\n")
		call pargr (sky[SKY_MEAN])
	    call printf ("sky median                        = %6.3f\n")
		call pargr (sky[SKY_MEDIAN])
	    call printf ("sky mode                          = %6.3f\n")
		call pargr (sky[SKY_MODE])
	    if (isky == SKY_SIGCLIP) {
		call printf ("sky after sigma clip              = %6.3f\n")
			call pargr (sky[SKY_SIGCLIP])
	    }
	    call printf ("sigma sky                         = %6.3f\n")
		call pargr (sigsky)
	    call printf ("number of pixels in star aperture = %d\n")
		call pargi (nstar)
	    call printf ("total star counts                 = %6.3f\n")
		call pargr (strsum)
	    call printf ("error in magnitude: dm(n)         = %6.3f\n")
		call pargr (err[ERR_N])
	    call printf ("error in magnitude: dm(sky)       = %6.3f\n")
		call pargr (err[ERR_SKY])
	    call printf ("error in magnitude: dm(noise)     = %6.3f\n")
		call pargr (err[ERR_NOISE])
	    call printf ("x position                        = %8.2f\n")
		call pargr (x)
	    call printf ("y position                        = %8.2f\n")
		call pargr (y)
	    call printf ("magnitude                         = %7.3f\n")
		call pargr (mag)
	    call printf ("sigma magnitude                   = %6.3f\n")
		call pargr (sig)
	} else {
	    call printf ("%4d  %8.2f  %8.2f  %7.3f  %6.3f  %8.3f  %7.3f  %4d\n")
		call pargi (starnum)
		call pargr (x)
		call pargr (y)
		call pargr (mag)
		call pargr (sig)
		call pargr (sky[isky])
		call pargr (sigsky)
		call pargi (nsky)
	}
end


# XYERROR - Sends the error message for the corresponding xysetup error code. 

procedure xyerror (ier, xi, yi)

int	ier			# error code
real	xi, yi			# star position

begin
	# Print error message
	switch (ier) {
	case 1:
	    call eprintf (
		"xysetup error 1: %d,%d star too close to edge\n")
	case 2:
	    call eprintf (
		"xysetup error 2: %d,%d data rectangle exceeds memory\n")
	default:
	    call eprintf (
		"xysetup error %d: %d,%d unknown\n")
		call pargi (ier)
	}

	# Print star coordinates
	call pargr (xi)
	call pargr (yi)
end


# PHOTERROR - Sends the error message for the corresponding photom error code.

procedure photerror (ier, xi, yi)

int	ier			# error code
real	xi, yi			# star position

begin
	# Print error message
	switch (ier) {
	case 1:
	    call eprintf (
		"photom error 1: %d,%d centering box too large\n")
	case 2:
	    call eprintf (
		"photom error 2: %d,%d star centroid shift too large\n")
	case 3:
	    call eprintf (
		"photom error 3: %d,%d too many iterations for centroid\n")
	case 4:
	    call eprintf (
		"photom error 4: %d,%d not enough sky pixels\n")
	case 5:
	    call eprintf (
		"photom error 5: %d,%d unknown sky evaluation mode\n")
	case 6:
	    call eprintf (
	        "photom error 6: %d,%d negative star magnitude\n")
	default:
	    call eprintf (
		"photom error %d: %d,%d unknown\n")
		call pargi (ier)
	}

	# Print star coordinates
	call pargr (xi)
	call pargr (yi)
end
