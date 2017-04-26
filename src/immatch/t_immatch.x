include	<error.h>
include	<mach.h>
include	<math/curfit.h>


# T_IMMATCH -- Match images against a reference

procedure t_immatch ()

bool	interactive			# run interactive ?
bool	imshift				# output script to run IMSHIFT ?
char	input[SZ_FNAME]			# input image name
char	reference[SZ_FNAME]		# reference image name
char	insec[SZ_FNAME]			# input image name with section
char	refsec[SZ_FNAME]		# reference image name with section
char	output[SZ_FNAME]		# output file name
char	section[SZ_LINE]		# image section to use
char	graphics[SZ_FNAME]		# graphics device name
int	fd				# output file descriptor
int	xmax, ymax			# maximum shifts from the center
int	i_ndim, i_npix, i_nlines	# input image dimension parameters
int	r_ndim, r_npix, r_nlines	# reference image dimension parameters
int	npix, nlines			# working buffer dimensions
real	width				# centering width
real	colcen, linecen			# centroid peaks
pointer	inlist				# input image list
pointer	imin				# input image descriptor
pointer	imref				# reference image descriptor
pointer	inline, incol			# projected input image line and column
pointer	refline, refcol			# projected ref. image line and column
pointer	corrline, corrcol		# correlated line and column
pointer	gp, gt
pointer	sp

bool	clgetb()
int	clgeti()
int	clpopnu(), clgfil()
int	open()
int	imgeti()
real	clgetr()
real	imm_centroid()
pointer	immap()
pointer	gopen(), gt_init()

begin
	# Get parameters
	inlist = clpopnu ("images")
	call clgstr ("reference", reference, SZ_FNAME)
	call clgstr ("output", output, SZ_FNAME)
	call clgstr ("section", section, SZ_LINE)
	xmax  = clgeti ("xmax")
	ymax  = clgeti ("ymax")
	width = clgetr ("width")
	interactive = clgetb ("interactive")
	imshift = clgetb ("imshift")
	call clgstr ("graphics", graphics, SZ_FNAME)

	# Append section and open reference image.
	call sprintf (refsec, SZ_FNAME, "%s%s")
	    call pargstr (reference)
	    call pargstr (section)
	imref = immap (refsec, READ_ONLY, 0)

	# Get and check image dimension
	r_ndim = imgeti (imref, "i_naxis")
	if (r_ndim > 2)
	    call error (0, "Image is not one or two dimensional")

	# Open output file
	fd = open (output, NEW_FILE, TEXT_FILE)

	# Get reference image number of lines and columns
	r_npix = imgeti (imref, "i_naxis1")
	if (r_ndim > 1)
	    r_nlines = imgeti (imref, "i_naxis2")
	else
	    r_nlines = 1

	# Compute number of lines and columns for working space.
	# These number have to be the next power of two.
	npix = 2 ** int (log (real (r_npix)) / log (2.0) + 1)
	if (r_ndim > 1)
	    nlines = 2 ** int (log (real (r_nlines)) / log (2.0) + 1)
	else
	    nlines = 1

	# Allocate space
	call smark  (sp)
	call salloc (inline,   npix,   TY_REAL)
	call salloc (refline,  npix,   TY_REAL)
	call salloc (corrline, npix,   TY_REAL)
	call salloc (incol,    nlines, TY_REAL)
	call salloc (refcol,   nlines, TY_REAL)
	call salloc (corrcol,  nlines, TY_REAL)

	# Project reference image into a single line, and single column
	call imm_project (imref, Memr[refcol], Memr[refline], nlines, npix)

	# Substract continuum from the line and column, and apply a cosine
	# bell filter to the input data. The bell is only applied to the
	# actual input points, and not to the power of two length
	call imm_substract (Memr[refline], Memr[refline], r_npix)
	call imm_cosbellr  (Memr[refline], Memr[refline], r_npix)
	if (r_ndim > 1) {
	    call imm_substract (Memr[refcol], Memr[refcol], r_nlines)
	    call imm_cosbellr  (Memr[refcol], Memr[refcol], r_nlines)
	}

	# Open graphics
	if (interactive) {
	    gp = gopen (graphics, NEW_FILE, STDGRAPH)
	    gt = gt_init()
	}

	# Loop over input list
	while (clgfil (inlist, input, SZ_FNAME) != EOF) {

	    # Append image section and open input image
	    iferr {
		call sprintf (insec, SZ_FNAME, "%s%s")
		    call pargstr (input)
		    call pargstr (section)
	        imin = immap (insec, READ_ONLY, 0)
	    } then {
		call erract (EA_WARN)
		next
	    }

	    # Get input image dimensions`
	    i_ndim = imgeti (imin, "i_naxis")
	    i_npix = imgeti (imin, "i_naxis1")
	    if (i_ndim > 1)
		i_nlines = imgeti (imin, "i_naxis2")

	    # Check reference image dimensions against input image dimensions
	    if (i_ndim != r_ndim || i_npix != r_npix) {
		call eprintf (
		"Warning: input and reference images have different dimensions")
		call imunmap (imin)
		next
	    }
	    if (i_ndim > 1 && i_nlines != r_nlines) {
		call eprintf (
		"Warning: input and reference images have different dimensions")
		call imunmap (imin)
		next
	    }

	    # Project input image lines and columns
	    call imm_project (imin, Memr[incol], Memr[inline], nlines, npix)

	    # Substract continuum from the line and column, and apply a cosine
	    # bell filter to the input data. The bell is only applied to the
	    # actual input points, and not to the power of two length
	    call imm_substract (Memr[inline], Memr[inline], r_npix)
	    call imm_cosbellr  (Memr[inline], Memr[inline], r_npix)
	    if (r_ndim > 1) {
		call imm_substract (Memr[incol], Memr[incol], r_nlines)
		call imm_cosbellr  (Memr[incol], Memr[incol], r_nlines)
	    }

	    # Correlate projections, adjust them, and find the centroids
	    call imm_correlate (Memr[inline], Memr[refline], Memr[corrline],
				npix)
	    call imm_adjust (Memr[corrline], Memr[corrline], npix)
	    linecen = imm_centroid (Memr[corrline], npix, xmax, width)
	    if (r_ndim > 1) {
	        call imm_correlate (Memr[incol], Memr[refcol], Memr[corrcol],
				    nlines)
		call imm_adjust (Memr[corrcol], Memr[corrcol], nlines)
		colcen  = imm_centroid (Memr[corrcol], nlines, ymax, width)
	    } else
		colcen = INDEFR

	    # Interactive plots
	    if (interactive) {
		call imm_graph (gp, gt,
				input, reference,
				Memr[incol], Memr[inline],
				Memr[refcol], Memr[refline],
				r_nlines, r_npix, r_ndim,
				Memr[corrcol], Memr[corrline],
				nlines, npix,
				colcen, linecen)
	    }

	    # Write centroids to output file along with image name
	    if (imshift) {

		# Change sign of shifts if they are defined. Otherwise
		# set them to zero, and issue warning message.
		if (IS_INDEFR (linecen)) {
		    linecen = 0.0
		    call eprintf ("Warning: undefined line shift for %s\n")
			call pargstr (input)
		} else
		    linecen = -linecen
		if (IS_INDEFR (colcen)) {
		    colcen = 0.0
		    if (r_ndim > 1) {
			call eprintf (
			    "Warning: undefined column shift for %s\n")
			    call pargstr (input)
		    }
		} else
		    colcen = -colcen

		# Write to output file
		call fprintf (fd,
		    "imshift (\"%s\", \"s_%s\", %g, %g, shifts_file=\"\")\n")
		    call pargstr (input)
		    call pargstr (input)
		    call pargr   (linecen)
		    call pargr   (colcen)

	    } else {
		call fprintf (fd, "%s   %s   %g   %g\n")
		    call pargstr (insec)
		    call pargstr (refsec)
		    call pargr   (linecen)
		    call pargr   (colcen)
	    }

	    # Close input image
	    call imunmap (imin)
	}

	# Free memory
	call sfree (sp)

	# Close graphics
	if (interactive) {
	    call gclose (gp)
	    call gt_free (gt)
	}

	# Close all
	call clpcls (inlist)
	call imunmap (imref)
	call close (fd)
end


# IMM_PROJECT -- Project image lines and colums by averaging them in
# a single sequential pass over all the image. The output line and column
# are not forced to have the same length than the image line and column
# lengths.

procedure imm_project (im, col, line, nlines, npix)

pointer	im			# image descriptor
real	col[nlines]		# projected colum (output)
real	line[npix]		# projected line (output)
int	nlines			# output number of lines
int	npix			# output number of columns

int	i, nd, nc, nl
real	dummy
pointer	ptr

int	imgeti()
pointer	imgl1r(), imgl2r()

begin
	# Clear output line
	call aclrr (line, npix)
	call aclrr (col, npix)

	# Take the minimum between the input image dimensions,
	# and output dimensions to avoid running out of bounds
	nd = imgeti (im, "i_naxis")
	nc = min (npix, imgeti (im, "i_naxis1"))
	if (nd > 1)
	    nl = min (nlines, imgeti (im, "i_naxis2"))

	# Branch on number of axis
	if (nd > 1) {

	    # Loop over all image lines summing all lines,
	    # and averaging each line to get the column average.
	    # Compute the line average at the end.
	    do i = 1, nl {
		ptr = imgl2r (im, i)
		call aaddr (Memr[ptr], line, line, nc)
		call aavgr (Memr[ptr], nc, col[i], dummy)
	    }
	    call adivkr (line, real (nl), line, nc)

	} else {

	    # Copy single image line to projected line
	    ptr = imgl1r (im)
	    call amovr (Memr[ptr], line, npix)
	}
end


# IMM_SUBSTRACT -- Substract continuum from an array. The operation can be
# performed in place.

procedure imm_substract (input, output, npts)

real	input[npts]		# input array
real	output[npts]		# output array
int	npts			# number of points

int	i, ier
pointer	x, y, w			# buffer poiinters
pointer	cv			# CURFIT descriptor
pointer	sp

begin
	# Allocate temporary buffers and initialize them
	call smark (sp)
	call salloc (x, npts, TY_REAL)
	call salloc (y, npts, TY_REAL)
	call salloc (w, npts, TY_REAL)
	call aclrr (Memr[w], npts)
	do i = 1, npts
	    Memr[x + i - 1] = real (i)

	# Initialize CURFIT descriptor
	call cvinit (cv, LEGENDRE, 2, real (1), real (npts))

	# Fit a line to the data to determine the continuum level
	call cvfit (cv, Memr[x], input, Memr[w], npts, WTS_UNIFORM, ier)
	if (ier == SINGULAR || ier == NO_DEG_FREEDOM) {
	    call sfree (sp)
	    call error (0, "imm_substract: error in fit")
	}

	# Generate the fitted continuum
	call cvvector (cv, Memr[x], Memr[y], npts)

	# Substract continuum from data 
	call asubr (input, Memr[y], output, npts)

	# Free CURFIT descriptor and memory
	call cvfree (cv)
	call sfree (sp)
end


# IMM_CORRELATE -- Correlate arrays. Both input arrays, and the output array
# are assumed to be of the same length. The number of points should be a
# power of two.

procedure imm_correlate (input1, input2, corr, npts)

real	input1[npts], input2[npts]	# input arrays
real	corr[ARB]			# correlation array (output)
int	npts				# number points

int	i, n2
real	minval, maxval, delta
pointer	fft1, fft2, prod
pointer	sp

begin
	# Allocate memory for transformations
	n2 = npts / 2 + 1
	call smark (sp)
	call salloc (fft1, n2, TY_COMPLEX)
	call salloc (fft2, n2, TY_COMPLEX)
	call salloc (prod, n2, TY_COMPLEX)

	# Compute FFT's
	call afftrx (input1, Memx[fft1], npts)
	call afftrx (input2, Memx[fft2], npts)

	# Multiply FFT's to get correlation
	do i = 1, n2
	    Memx[prod + i - 1] = Memx[fft1 + i - 1] *
				 conjg (Memx[fft2 + i - 1]) / real (n2)

	# Take the inverse transformation of the product
	call aiftrx (Memx[prod], corr, npts)

	# Normalize the output so the range is always from zero to one.
	call alimr (corr, npts, minval, maxval)
	delta = maxval - minval
	if (delta > EPSILONR) {
	    do i = 1, npts
		corr[i] = (corr[i] - minval) / delta
	}

	# Free memory
	call sfree (sp)
end


# IMM_ADJUST -- Adjust correlated arrays so negative lags thay lay at the
# end of the array are moved to the beginning, and possitive lags that lay
# at the beginning are move to the end. This allows the centering algorithm
# work properly. The operation can be perfomed in place.

procedure imm_adjust (input, output, npts)

real	input[npts]		# input array
real	output[npts]		# output array
int	npts			# number of points

int	i, n2
real	temp

begin
	n2 = npts / 2

	do i = 1, n2 {
	    temp = input[n2 + i]
	    output[n2 + i] = input[i]
	    output[i] = temp
	}
end


# IMM_CENTROID -- Determine peak centroid around the maximum value in
# the data. The search for the peak is constrained by a maximum radius
# from the center of the input array.

real procedure imm_centroid (input, npts, radius, width)

real	input[npts]		# input array
int	npts			# number of points
int	radius			# maximum radius from the center
real	width			# centering width

int	i, i1, i2, imax
real	maxval

real	c1d_center()

begin
	# Set the range where to search for the maximum value. If the
	# radius is undefined then the full range is used.
	if (IS_INDEFI (radius)) {
	    i1 = 1
	    i2 = npts
	} else {
	    i1 = max (1,    npts / 2 - radius)
	    i2 = min (npts, npts / 2 + radius)
	}

	# Initialize variables.
	imax   = i1
	maxval = input[i1]

	# Look for the maximum value
	do i = i1 + 1, i2 {
	    if (input[i] > maxval) {
		imax   = i 
		maxval = input[i]
	    }
	}

	# Return centroid around the maximum relative
	# to the center of the array
	call c1d_params (INDEFI, INDEFR)
	return (c1d_center (real (imax), input, npts, width) - npts / 2 - 1)
end
