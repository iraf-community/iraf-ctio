# VELOCITY -- Builds a picture having velocity as its pixel value.
#
# Following the	model of Williams and Schommer,	the data cube
# is fit along the z-axis to a Gaussian. The resulting fit parameters,
# central wavelength (radial velocity),	peak intensity above sky,
# FWHM (resolution), and continuum level, plus their associated	errors,
# are stored as	8 new pictures.	These will be type REAL	pixels.
#
# The Gaussian fit routine, using differential least-squares
# is a FORTRAN routine supplied	by Schommer and	Williams.

include	<imio.h>
include	<imhdr.h>
include	<imset.h>
include	<fset.h>
include <gset.h>
include	<mach.h>

# Define the output picture indices			image suffixes|

define		CONT	1	# Continuum level		--> con
define		INTE	2	# Line intensity		--> int
define		VELO	3	# Velocity			--> vel
define		VDIS	4	# Velocity dispersion (FWHM)	--> vdi
define		E_CO	5	# Error in continuum		--> eco
define		E_IN	6	# Error in intensity		--> ein
define		E_VE	7	# Error in velocity		--> eve
define		E_VD	8	# Error in velocity dispersion	--> evd

# Each band of the cube	will be	buffered separately - define a maximum
# number of buffers.

define		MAX_NBUF	100

# Bad Pixels were defined equal	to -666	by Williams. A reasonable
# number is required for compatibility with IRAF tasks such as
# SPLOT	which don't know about special pixel values. For the
# moment, adopt	EPSILONR since this will probably not affect anything
# too seriously.

define		BADPIX		EPSILONR	# Fit failure indicator
define		CSPEED		2.998E5		# Speed of light roughly

procedure t_velocity ()

char	cube_image[SZ_FNAME], root[SZ_FNAME], image_out[SZ_FNAME+1,8]
char	metacode[SZ_FNAME], dir_plot[SZ_FNAME]
int	i, j, k
int	x1,	x2, y1,	y2
int	navgx, navgy
int	ncols, nrows, nbands
int	ncols_out, nrows_out
int	x_offset, y_offset
int	fdir, fmc, gp, navg
bool	verbose, retry, make_plot
real	coef[3]
real	lambda_rest, lambda1, lambda2
real	v_limit
real	ans[4], errors[4]
real	rmin, rmax
pointer	sp
pointer	xshift,	yshift,	xc, yc,	lambda0, sky, norm, etgap
pointer	flux, lambda
pointer	im, im_out[8], buf_out[8], buf[MAX_NBUF], line[MAX_NBUF]
pointer	avgline[MAX_NBUF]

int	clgeti()
int	open(), gopen()
real	clgetr()
bool	clgetb()
pointer	immap(), impl2r()

begin
	# Get cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Get output root name
	call clgstr ("root", root, SZ_FNAME)

	# Get rest wavelength of line of interest
	# Note	that for high dispersion work, this may	have to	be a double
	lambda_rest = clgetr ("lambda_rest")

	# Get subraster range
	x1 = clgeti ("x1")
	x2 = clgeti ("x2")
	y1 = clgeti ("y1")
	y2 = clgeti ("y2")

	# Get block averaging parameters
	navgx = clgeti	("navgx")
	navgy = clgeti	("navgy")

	# Get x and y offsets due to possible subraster extraction
	x_offset = clgeti ("x_offset")
	y_offset = clgeti ("y_offset")

	# Get the maximum velocity error acceptable before averaging
	v_limit = clgetr ("v_limit")

	# Does user want to try block averaging on pixels that
	# did not give any answer? This is probably most pixels
	# in the picture, and so will nearly double the cp time.
	retry = clgetb ("block")

	# Plotting options
	# Are plots desired?
	make_plot = clgetb ("plot")

	# If so, then get the names for the output directory of the
	# the pixel vs frame number.
	# Also get the plot metacode file name
	if (make_plot) {
	    call clgstr ("dir_plot", dir_plot, SZ_FNAME)
	    call clgstr ("metacode", metacode, SZ_FNAME)

	    fdir = open (dir_plot, NEW_FILE, TEXT_FILE)
	    fmc  = open (metacode, NEW_FILE, BINARY_FILE)
	    gp   = gopen ("stdvdm", NEW_FILE, fmc)

	    call velinit
	}

	# Print a running status?
	verbose = clgetb ("verbose")

	call fseti (STDOUT, F_FLUSHNL,	YES)
	call printf ("\n")

	# Open	cube to	determine number of bands
	iferr (im = immap (cube_image,	READ_ONLY, 4*MIN_LENUSERAREA))
	    call error	(0, "Cannot open image cube")

	ncols	= IM_LEN (im,1)
	nrows	= IM_LEN (im,2)
	nbands	= IM_LEN (im,3)

	# Set analysis	limits
	if (x1	== 0)
	    x1	= 1
	if (x2	== 0)
	    x2	= ncols
	if (y1	== 0)
	    y1	= 1
	if (y2	== 0)
	    y2	= nrows

	ncols_out = x2	- x1 + 1
	nrows_out = y2	- y1 + 1

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
	call extr_hdr (im, nbands, Memr[xshift], Memr[yshift],	Memr[xc],
	    Memr[yc], Memr[lambda0], Memr[etgap], Memr[sky], Memr[norm], coef)

	# Get max radius
	call get_radii (x1, y1, x2, y2, x_offset, y_offset, Memr[xc], Memr[yc],
		        Memr[xshift], Memr[yshift], nbands, rmin, rmax)

	call printf ("\n")

	# Open	the output images - use	the root and pre-defined suffixes
	# for their names.
	call sprintf (image_out[1,1], SZ_FNAME, "%scon")
	    call pargstr (root)

	call sprintf (image_out[1,2], SZ_FNAME, "%sint")
	    call pargstr (root)

	call sprintf (image_out[1,3], SZ_FNAME, "%svel")
	    call pargstr (root)

	call sprintf (image_out[1,4], SZ_FNAME, "%svdi")
	    call pargstr (root)

	call sprintf (image_out[1,5], SZ_FNAME, "%seco")
	    call pargstr (root)

	call sprintf (image_out[1,6], SZ_FNAME, "%sein")
	    call pargstr (root)

	call sprintf (image_out[1,7], SZ_FNAME, "%seve")
	    call pargstr (root)

	call sprintf (image_out[1,8], SZ_FNAME, "%sevd")
	    call pargstr (root)

	do i =	1, 8 {
	    iferr (im_out[i] =	immap (image_out[1,i], NEW_COPY, im)) {
		call eprintf ("Cannot	open output image: %s\n")
		    call pargstr (image_out[1,i])
		call error (0, "")
	    }

	    # Revise the header parameters
	    IM_NDIM (im_out[i])   = 2
	    IM_LEN  (im_out[i],1) = ncols_out
	    IM_LEN  (im_out[i],2) = nrows_out
	    IM_PIXTYPE	(im_out[i])= TY_REAL
	}

	# Compute the range of wavelength covered by the system, roughly
	call lam_range (nbands, Memr[lambda0], Memr[etgap], coef, rmin, rmax,
			lambda1, lambda2)

	# For each pixel, compute the fit in the z-direction
	# Buffer in rows by image plane. Block	average	if necessary.
	do j =	y1, y2 {
	    do	i = 1, nbands
		call block (im, i, buf[i], x1, x2, j, navgy, nrows, line[i],
			avgline[i])

	    # Map output buffers
	    do	i = 1, 8
		buf_out[i] = impl2r (im_out[i], j-y1+1)

	    # Perform fit
	    do	i = x1,	x2 {
		navg = 1
		call gaussfit	(i, j, nbands, 1, x1, ncols, line, Memr[xshift],
		    Memr[yshift], Memr[xc], Memr[yc],	Memr[lambda0],
		    Memr[etgap], Memr[sky], Memr[norm], coef,
		    x_offset, y_offset, lambda_rest, ans, errors, 
		    Memr[flux], Memr[lambda])

		if ((errors[VELO] > v_limit)  ||
		   ((ans   [VELO] == BADPIX) && retry)) {

		    navg = (navgx + navgy)/2
		    call gaussfit (i, j, nbands, navgx, x1, ncols, avgline, 
			Memr[xshift], Memr[yshift], Memr[xc], Memr[yc],
			Memr[lambda0], Memr[etgap], Memr[sky], Memr[norm],
			coef, x_offset, y_offset, lambda_rest, ans, errors,
			Memr[flux], Memr[lambda])
		}

		if (make_plot)
		    call velplot (gp, fdir, i, j, nbands, Memr[flux], 
			Memr[lambda], lambda_rest, ans, navg, lambda1, lambda2,
			x2, y2)

		# Load answers into output buffers
		do k = 1, 4 {
		    Memr[buf_out[k  ]+i-x1] =	ans[k]
		    Memr[buf_out[k+4]+i-x1] =	errors[k]
		}
	    }

	    if	(verbose) {
		call printf ("Row %d vels: %7.1f %7.1f %7.1f %7.1f %7.1f\n")
		    call pargi (j)
		    call pargr (Memr[buf_out[3]+ncols_out/6])
		    call pargr (Memr[buf_out[3]+ncols_out*2/6])
		    call pargr (Memr[buf_out[3]+ncols_out*3/6])
		    call pargr (Memr[buf_out[3]+ncols_out*4/6])
		    call pargr (Memr[buf_out[3]+ncols_out*5/6])
	    }
	}

	call sfree (sp)
	
	if (make_plot) {
	    call gclose (gp)
	    call close (fdir)
	    call close (fmc)
	}

	call imunmap (im)
	do i =	1, 8
	    call imunmap (im_out[i])

end

# BLOCK	-- Block average an image plane	in rows, between column	limits

procedure block	(im, band, buf,	x1, x2,	y, navgy, maxy,	line, avgline)

pointer	im, buf, line, avgline
int	band, x1, x2, y, navgy, maxy

int	i, j, y1, y2, nx, ny, index
long	vs[IM_MAXDIM], ve[IM_MAXDIM]

pointer	imggss()

begin
	# Set limits
	y1 = y	- navgy/2
	y2 = y1 + navgy - 1
	y1 = max (1, y1)
	y2 = min (y2, maxy)

	ny = y2 - y1 +	1
	nx = x2 - x1 +	1

	call amovkl (long(1), vs, IM_MAXDIM)
	call amovkl (long(1), ve, IM_MAXDIM)

	vs[1] = x1
	vs[2] = y1
	vs[3] = band

	ve[1] = x2
	ve[2] = y2
	ve[3] = band

	# Map a general SHORT 3D section
	buf = imggss (im, vs, ve, 3)

	# Add up the pixels
	call aclrl (Meml[avgline], nx)

	do i =	1, ny {
	    index = (i-1) * nx

	    do	j = 1, nx {
		Meml[avgline+j-1] = Meml[avgline+j-1] + Mems[buf+index]
		index	= index	+ 1
	    }
	}

	call adivkl (Meml[avgline], long(navgy), Meml[avgline], nx)

	# Also save the current single line
	index = (y - y1) * nx
	do j = 1, nx
	    Meml[line+j-1] = Mems[buf+index+j-1]

end

# EXTR_HDR -- Extract all the needed header parameters

procedure extr_hdr (im,	nbands,	xshift,	yshift,	xc, yc,	lambda0,
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

 	call printf ("Band   xsh    ysh    gap    lam0     xc")
	call printf ("     yc   sky   norm\n")

	do i =	1, nbands {
	call printf ("%3d %6.2f %6.2f %6.3f %7.2f %6.1f %6.1f %5.1f %6.3f\n")
	call pargi (i)
	call pargr (xshift[i])
	call pargr (yshift[i])
	call pargr (etgap[i])
	call pargr (lambda0[i])
	call pargr (xc[i])
	call pargr (yc[i])
	call pargr (sky[i])
	call pargr (norm[i])
	}
end

# GAUSSFIT -- The entire reason	for this package is in this subroutine
#
# Each respective pixel	from the y-block averaged lines	are blocked in x
# and then moved to a work array. They are corrected for:
#
#	1. Sky subtraction
#	2. Normalization factor
#	3. lambda0 changes
#	4. centering differences
#
# Then the 1D array is fit to a	Gaussian using differential least-squares
# as supplied by Williams. The 8 output	values (4 + 4 errors) are stored
# in the 8 output buffers.

procedure gaussfit (ix,	iy, nbands, navgx, xs, maxx, line, xshift, yshift, xc,
		    yc, lambda0, etgap, sky, norm, coef, xoff, yoff,
		    lambda_rest, ans, errors, fl, vl)

int	ix, iy, nbands, navgx, xs, maxx
int	xoff, yoff
real	xshift[ARB], yshift[ARB], xc[ARB], yc[ARB]
real	lambda0[ARB], etgap[ARB], sky[ARB], norm[ARB]
real	coef[3]
real	lambda_rest
real	ans[4], errors[4]
real	fl[ARB], vl[ARB]
pointer	line[ARB]

int	i, j, x1, x2, nx
int	order
long	lsum
real	x, y, radius, lambda
real	flux[MAX_NBUF], vel[MAX_NBUF]
real	ans2[4], errors2[4]

real	sqrt(), cos(), atan()

begin
	# Compute the wavelength of the pixels
	# This	depends	on the radius of the pixel, which in turn,
	# depends on the shifts and centers involved.
	# Note	that the shifts	are defined by IMSHIFT to be positive
	# when	the image is moved to larger pixel positions.
	# We want the original	pixel locations	in the frame.

	do i =	1, nbands {
	    x = (ix - xshift[i] + xoff - 1) - xc[i]
	    y = (iy - yshift[i] + yoff - 1) - yc[i]
	    radius = sqrt (x*x	+ y*y)

	    lambda = (lambda0[i] + coef[2] * etgap[i])	*
		     cos (atan (radius / coef[3]))

	    vel[i] = lambda
	    vl[i]  = lambda
	}

	# Load	pixel values, blocking if necessary
	if (navgx == 1) {
	    do	i = 1, nbands
		flux[i] = (Meml[line[i]+ix-xs]	- sky[i]) * norm[i]

	} else	{
	    x1	= max (1, ix - navgx/2)
	    x2	= min (maxx, ix	+ navgx/2)
	    nx	= x2 - x1 + 1

	    do	i = 1, nbands {
		lsum = 0
		do j = x1, x2
		    lsum = lsum + Meml[line[i]+j-xs]

		flux[i] = (lsum/nx - sky[i]) * norm[i]
	    }
	}
	# Save flux values
	do i = 1, nbands
	    fl[i] = flux[i]

	# We now have (flux vs	lambda)	to fit,	so lets	do it.
	# First do 3rd	order, ignoring	dispersion
	order = 3
	call lfit (vel, flux, order, ans, errors, lambda_rest,	BADPIX,	nbands)

	# Check for satisfactory fit
	if (errors[1] != BADPIX) {

	    # Refit with all parameters
	    order = 4
	    do	i = 1, 3
		ans2[i] = ans[i]

	    call lfit (vel, flux, order, ans2,	errors2, lambda_rest,
		BADPIX, nbands)

	    # Restore old answers if error occurred with 4th parameter
	    if	(errors2[1] != BADPIX) {
		do i = 1, 4 {
		    ans[i]	= ans2[i]
		    errors[i]	= errors2[i]
		}
	    }

	# Flag	bad solution
	} else	{
	    do	i = 1, 4 {
		ans[i]    = BADPIX
		errors[i] = BADPIX
	    }
	}
end

# VELPLOT -- Plot the velocity spectrum at each pixel

define		VIEW_DELTA	0.19	# Separation between viewports
define		VIEW_START	0.05	# Lower viewport position

procedure velplot (gp, fdir, i, j, nbands, flux, lambda, lambda_rest, 
		   ans, navg, lambda1, lambda2, imax, jmax)

int	gp, fdir, i, j, nbands, navg
int	imax, jmax
real	lambda_rest, lambda1, lambda2
real	flux[ARB], lambda[ARB], ans[4]

char	title[SZ_FNAME]
int	ifirst, ilast, jfirst, jlast, iframe
int	startup, sigma
int	k
real	x1, x2, y1, y2, ymin, ymax
real	lambda_ctr
real	sig_lam
real	flux_fit[MAX_NBUF]

common	/velcom/startup

begin
	# Initialization
	if (startup == YES) {
	    startup = NO
	    x1 = VIEW_START
	    y1 = VIEW_START
	    iframe = 1

	    # Select: no minor ticks, no x-axis label or tick labels,
	    # 	  limited major ticks, small titles and y tick labels
	    #
	    call gseti (gp, G_NMINOR, 0)
	    call gseti (gp, G_XLABELAXIS, NO)
	    call gseti (gp, G_YNMAJOR, 4)
	    call gseti (gp, G_XNMAJOR, 4)
	    call gsetr (gp, G_TITLESIZE, 0.5)
	    call gsetr (gp, G_TICKLABELSIZE, 0.5)
	    call gsetr (gp, G_MAJORLENGTH, 0.01)
	}

	if (x1 == VIEW_START && y1 == VIEW_START) {
	    ifirst = i
	    jfirst = j
	}

	x2 = x1 + VIEW_DELTA - VIEW_START
	y2 = y1 + VIEW_DELTA - VIEW_START

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

	# Build label: pixel i,j; derived lambda center, sigma in km/s,
	#		and the number of averaging pts in the solution
	call sprintf (title, SZ_FNAME, "%03d,%03d %7.2f,%03d,%01d")
	call pargi (i)
	call pargi (j)
	call pargr (lambda_ctr)
	call pargi (sigma)
	call pargi (navg)
	
	# Select viewport
	call gsview (gp, x1, x2, y1, y2)

	# Define the user coordinate system
	call gswind (gp, lambda1, lambda2, ymin, ymax)

	# For the bottom-most line, label x-axis tick marks
	if (y1 != VIEW_START)
	    call gseti (gp, G_XLABELTICKS, NO)

	# Draw axes and label
	call glabax (gp, title, "", "")

	# Draw the data as little "+"s
	call gpmark (gp, lambda, flux, nbands, GM_PLUS, 0.004, 0.004)

	# Draw the fit as a solid line
	call gpline (gp, lambda, flux_fit, nbands)

	# Draw the center position
	call gline (gp, lambda_ctr, ymin, lambda_ctr, ymax)

	# If last plot per page or last plot at all, enter into directory.
	# And advance the frame
	if (((x1+2*VIEW_DELTA-VIEW_START > 1.0)  && 
	     (y1+2*VIEW_DELTA-VIEW_START > 1.0)) ||
	    ((i == imax) && (j == jmax))) {
	    ilast = i
	    jlast = j
	    call fprintf (fdir, "frame %3d: %03d:%03d - %03d:%03d\n")
		call pargi (iframe)
		call pargi (ifirst)
		call pargi (jfirst)
		call pargi (ilast)
		call pargi (jlast)

	    call gframe (gp)
	    call gseti (gp, G_XLABELTICKS, YES)

	    x1 = VIEW_START
	    y1 = VIEW_START
	    iframe = iframe + 1
	} else if ((x1+2*VIEW_DELTA-VIEW_START) > 1.0)  {
	    x1 = VIEW_START
	    y1 = y1 + VIEW_DELTA
	} else
	    x1 = x1 + VIEW_DELTA

end

# VELINIT -- Initialize the startup for the velocity plot

procedure velinit

int	startup

common	/velcom/startup

begin
	startup = YES
end

# LAM_RANGE -- Estimate the range in wavelength of the observations for
#		creating uniform plots

procedure olam_range (nbands, lambda0, etgap, coef, lambda1, lambda2)

int	nbands
real	lambda0[ARB], etgap[ARB], coef[3]
real	lambda1, lambda2

real	etmin, etmax, l0min, l0max, rmax

begin
	# Find band having the lowest and highest gap and lambda0
	call alimr (  etgap, nbands, etmin, etmax)
	call alimr (lambda0, nbands, l0min, l0max)

	# Smallest wavelength is at large radius - guess by using R=500
	# We only have to be slightly conservative
	rmax = 100.0
	lambda1 = (l0min + coef[2] * etmin) * cos (atan (rmax/coef[3]))

	# Largest wavelength is at the center - this one's easy
	lambda2 = l0max + coef[2] * etmax
end


# LAM_RANGE -- Estimate the range in wavelength of the observations for
#		creating uniform plots

procedure lam_range (nbands, lambda0, etgap, coef, rmin, rmax, lambda1, lambda2)

int	nbands
real	lambda0[ARB], etgap[ARB], coef[3]
real	rmin, rmax
real	lambda1, lambda2

int	i

begin
	# Calculate the smallest and largest wavelengths for
	# all the bands
	lambda1 = MAX_REAL
	lambda2 = - MAX_REAL
	do i = 1, nbands {
	    lambda1 = min (lambda1, (lambda0[i] + coef[2] * etgap[i]) * 
				    cos (atan (rmax / coef[3])))
	    lambda2 = max (lambda2, (lambda0[i] + coef[2] * etgap[i]) *
				    cos (atan (rmin / coef[3])))
	}
end
