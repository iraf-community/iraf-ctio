# AVGVEL - 
#
# Following the	model of Williams and Schommer,	the data cube
# is fit along the z-axis to a Gaussian. The resulting fit parameters,
# central wavelength (radial velocity),	peak intensity above sky,
# FWHM (resolution), and continuum level, plus their associated	errors,
# are stored in a text file.
#
# The Gaussian fit routine, using differential least-squares
# is a FORTRAN routine supplied	by Schommer and	Williams.

include	<imio.h>
include	<imhdr.h>
include	<imset.h>
include <gset.h>

# Each band of the cube	will be	buffered separately - define a maximum
# number of buffers.
define		MAX_NBUF	100

# Define the output indices
define		CONT	1	# Continuum level
define		INTE	2	# Line intensity
define		VELO	3	# Velocity
define		VDIS	4	# Velocity dispersion (FWHM)
define		E_CO	5	# Error in continuum
define		E_IN	6	# Error in intensity
define		E_VE	7	# Error in velocity
define		E_VD	8	# Error in velocity dispersion

# Speed of light roughly
define		CSPEED		2.998E5	

procedure t_avgvel ()

char	cube_image[SZ_FNAME]		# input image name
char	output[SZ_FNAME]		# output file name
char	device[SZ_FNAME]		# output device name
int	x, y				# cursor position
int	nrings				# number of rings to average
int	i
int	x1, x2, y1, y2			# subraster range
int	navgx, navgy			# block averaging area
int	x_offset, y_offset		# offset for subraster
int	ncols, nrows, nbands
int	fd				# output file descriptor
int	gp, navg
bool	verbose, make_plot, make_title
real	coef[3]
real	lambda_rest, lambda1, lambda2
real	ans[4], errors[4]
real	dmin, dmax
pointer	sp
pointer	xshift,	yshift,	xc, yc,	lambda0, sky, norm, etgap
pointer	flux, lambda
pointer	im, buf[MAX_NBUF], line[MAX_NBUF]
pointer	avgline[MAX_NBUF]

int	clgeti()
int	open(), gopen(), access()
real	clgetr()
bool	clgetb()
pointer	immap()

begin
	# Get cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Get output file name
	call clgstr ("output", output, SZ_FNAME)

	# Get rest wavelength of line of interest
	# Note that for high dispersion work, this may have to be a double
	lambda_rest = clgetr ("lambda_rest")

	# Get pixel coordinates
	x = clgeti ("x")
	y = clgeti ("y")

	# Get number of rings to average
	nrings = clgeti ("nrings")

	# Get x and y offsets due to possible subraster extraction
	x_offset = clgeti ("x_offset")
	y_offset = clgeti ("y_offset")

	# Evaluate subraster range
	x1 = x
	x2 = x
	y1 = y
	y2 = y

	# Evaluate block averaging parameters
	navgx = 2 * nrings + 1
	navgy = 2 * nrings + 1

	# Are plots desired ?
	make_plot = clgetb ("plot")

	# Is output to the standard output desired ?
	verbose = clgetb ("verbose")

	# If so, then get the name of the device
	if (make_plot)
	    call clgstr ("device", device, SZ_FNAME)

	# Check if the output file already exists and open
	# it in append mode
	make_title = (access (output, 0, 0) == NO)
	iferr (fd = open (output, APPEND, TEXT_FILE))
	    call error (0, "Cannot open output file")

	# Open	cube to	determine number of bands
	iferr (im = immap (cube_image, READ_ONLY, 4*MIN_LENUSERAREA))
	    call error	(0, "Cannot open image cube")
	else {
	    ncols = IM_LEN (im,1)
	    nrows = IM_LEN (im,2)
	    nbands = IM_LEN (im,3)
	}

	# Set analysis	limits
	if (x1	== 0)
	    x1	= 1
	if (x2	== 0)
	    x2	= ncols
	if (y1	== 0)
	    y1	= 1
	if (y2	== 0)
	    y2	= nrows

	# Allocate space for the calibration arrays
	call smark (sp)
	call salloc (xshift , nbands, TY_REAL)
	call salloc (yshift , nbands, TY_REAL)
	call salloc (xc     , nbands, TY_REAL)
	call salloc (yc     , nbands, TY_REAL)
	call salloc (lambda0, nbands, TY_REAL)
	call salloc (etgap  , nbands, TY_REAL)
	call salloc (sky    , nbands, TY_REAL)
	call salloc (norm   , nbands, TY_REAL)

	# And for the spectrum
	call salloc (flux   , nbands, TY_REAL)
	call salloc (lambda , nbands, TY_REAL)

	# Allocate space for block averaged lines and extracted lines
	do i =	1, nbands {
	    call salloc (   line[i], ncols, TY_LONG)
	    call salloc (avgline[i], ncols, TY_LONG)
	}

	# Allocate 1 input buffer per band
	call imseti (im, IM_NBUFS, nbands)

	# Extract the header parameters
	call extrr_hdr (im, nbands, Memr[xshift], Memr[yshift],	Memr[xc],
	    Memr[yc], Memr[lambda0], Memr[etgap], Memr[sky], Memr[norm], coef)

	# Calculate max radius
	call get_radii (x1, y1, x2, y2, x_offset, y_offset, 
	    Memr[xc], Memr[yc], Memr[xshift], Memr[yshift], nbands, dmin, dmax)


	# Compute the range of wavelength covered by the system, roughly
	call lam_range (nbands, Memr[lambda0], Memr[etgap], coef, dmin, dmax,
			lambda1, lambda2)

	# Compute the fit in the z-direction for the pixel
	# Buffer in rows by image plane. Block	average	if necessary.
	do i = 1, nbands
	    call block (im, i, buf[i], x1, x2, y1, navgy, nrows, line[i],
			avgline[i])

        navg = (navgx + navgy)/2
        call gaussfit (x1, y1, nbands, navgx, x1, ncols, avgline, 
		       Memr[xshift], Memr[yshift], Memr[xc], Memr[yc],
		       Memr[lambda0], Memr[etgap], Memr[sky], Memr[norm],
		       coef, x_offset, y_offset, lambda_rest, ans, errors,
		       Memr[flux], Memr[lambda])

	# Plot the velocity fit
	if (make_plot) {
            gp = gopen (device, NEW_FILE, STDGRAPH)

	    call velgraph (gp, cube_image, x1, y1, nbands, Memr[flux], 
			   Memr[lambda], lambda_rest, ans, navg,
			   lambda1, lambda2, x2, y2)

	    call gclose (gp)
	}


	# Print results to output file
	call print_results (fd, x1, y1, ans, errors, make_title)

	# Print results to standard output
	if (verbose)
	    call print_results (STDOUT, x1, y1, ans, errors, make_title)

	# Free temporary space
	call sfree (sp)
	
	# Close input image
	call imunmap (im)

	# Close output file
	call close (fd)
end


# PRINT_RESULTS - Print results to output file

procedure print_results (fd, x, y, ans, errors, make_title)

int	fd		# file descriptor
int	x, y		# pixel coordinates
real	ans[ARB]	# results
real	errors[ARB]	# errors
bool	make_title	# print titles

int	k

begin
	# Write title into output file if necessary
	if (make_title) {
	    call fprintf (fd,
		"%4.4s %4.4s %8.8s %8.8s %8.8s %8.8s %8.8s %8.8s %8.8s %8.8s\n")
		call pargstr ("X")
		call pargstr ("Y")
		call pargstr ("Cont")
		call pargstr ("Inten")
		call pargstr ("Veloc")
		call pargstr ("Disp")
		call pargstr ("Err_con")
		call pargstr ("Err_int")
		call pargstr ("Err_vel")
		call pargstr ("Err_dis")
	}

	# Write values into output file
	call fprintf (fd,
	    "%4.4d %4.4d %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f\n")
	call pargi (x)
	call pargi (y)
	do k = 1, 4
	    call pargr (ans[k])
	do k = 1, 4
	    call pargr (errors[k])
end


# EXTRR_HDR -- Extract all the needed header parameters, but don't print
# the information on the standard output as extr_hdr() does.

procedure extrr_hdr (im, nbands, xshift, yshift, xc, yc, lambda0,
		     etgap, sky, norm, coef)

pointer	im
int	nbands
real	xshift[ARB], yshift[ARB], xc[ARB],	yc[ARB], lambda0[ARB]
real	etgap[ARB], sky[ARB], norm[ARB]
real	coef[3]

char	param[SZ_FNAME]
int	i

real	get_hdrr()

begin
	# For each parameter, build the name, and extract
	# While this should be	MUCH more efficient, it	is
	# probably small compared to the total	compute	time
	# required to do the fitting.

	do i =	1, nbands {

	    # XSHIFT
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("XSHIFT")
		call pargi (i)
	    xshift[i] = get_hdrr (im, param)

	    # YSHIFT
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("YSHIFT")
		call pargi (i)
	    yshift[i] = get_hdrr (im, param)

	    # FPZ
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("FPZ")
		call pargi (i)
	    etgap[i] =	get_hdrr (im, param)

	    # XC
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("XC")
		call pargi (i)
	    xc[i] = get_hdrr (im, param)

	    # YC
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("YC")
		call pargi (i)
	    yc[i] = get_hdrr (im, param)

	    # LAMBDA0
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("LAMBDA")
		call pargi (i)
	    lambda0[i]	= get_hdrr (im,	param)

	    # SKY
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("SKY")
		call pargi (i)
	    sky[i] = get_hdrr (im, param)

	    # NORM
	    call sprintf (param, SZ_FNAME, "%s%02d")
		call pargstr ("NORM")
		call pargi (i)
	    norm[i] = get_hdrr	(im, param)
	}

	# Get the 3 dispersion	solution coefficients
	coef[1] = get_hdrr (im, "COEF1")
	coef[2] = get_hdrr (im, "COEF2")
	coef[3] = get_hdrr (im, "COEF3")
end


# VELGRAPH -- Graph the velocity spectrum at each pixel

procedure velgraph (gp, name, i, j, nbands, flux, lambda, lambda_rest, 
		    ans, navg, lambda1, lambda2, imax, jmax)

int	gp			# graphics descriptor
char	name[ARB]		# image name
int	i, j			# pixel coordinates
int	nbands			# number of bands
int	navg			# number of points averaged
int	imax, jmax
real	lambda_rest		# lambda rest
real	lambda1, lambda2
real	flux[ARB]
real	lambda[ARB]
real	ans[4]

char	title[SZ_LINE]
int	sigma
int	k
real	ymin, ymax
real	lambda_ctr
real	sig_lam
real	flux_fit[MAX_NBUF]

begin
	# Select no minor ticks 
	call gseti (gp, G_NMINOR, 0)

	# Calculate title info
	lambda_ctr = (1.0 + ans[3]/CSPEED) * lambda_rest
	sigma = int (max (min (999.0, ans[4]), 0.0))
	sig_lam = ans[4]/CSPEED * lambda_rest

	# Get y plot limits
	call alimr (flux, nbands, ymin, ymax)

	# Override ymin so all plots are on a zero based scale
	if (ymin > 0.0)
	    ymin = 0.0
	else
	    ymin = 1.2 * ymin

	# Allow some extra
	ymax = 1.2 * ymax

	# Compute the fit values
	do k = 1, nbands
	    flux_fit[k] = ans[1] + ans[2] * 
		exp (-0.5 * ((lambda[k]-lambda_ctr) / sig_lam)**2)

	# Build title with image name, pixel coordiantes, derived lambda
	# center, sigma in km/s, and the number of averaging points
	# in the solution
	call sprintf (title, SZ_LINE,
	    "image=%s x=%d y=%d navg=%d\ncenter=%7.2f vel=%7.2f disp=%7.2f")
	    call pargstr (name)
	    call pargi (i)
	    call pargi (j)
	    call pargi (navg)
	    call pargr (lambda_ctr)
	    call pargr (ans[VELO])
	    call pargr (ans[VDIS])
	
	# Select viewport
	call gsview (gp, 0.15, 0.85, 0.15, 0.85)

	# Define the user coordinate system
	call gswind (gp, lambda1, lambda2, ymin, ymax)

	# Draw axes and label
	call glabax (gp, title, "lambda", "velocity")

	# Draw the data as little "+"s
	call gpmark (gp, lambda, flux, nbands, GM_PLUS, 0.04, 0.04)

	# Draw the fit as a solid line
	call gpline (gp, lambda, flux_fit, nbands)

	# Draw the center position
	call gline (gp, lambda_ctr, ymin, lambda_ctr, ymax)
end
