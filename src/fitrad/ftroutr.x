include	"fitrad.h"

# Map cveval function name for reals
define	rcveval		cveval


# FTR_OUTPUT -- Output data to the image

procedure ftr_outputr (imin, imout, cv, option, xc, yc, rmax)

pointer	imin				# IMIO descriptor for input image
pointer	imout				# IMIO descriptor for output image
pointer	cv				# CURFIT pointer
int	option				# output option
int	xc, yc				# center coordinates
int	rmax				# maximum radius

int	line, col, nlines, ncols
real	r, func, fit

int	imgeti()
pointer	imgl2r(), impl2r()
real	rcveval()

begin
	# Get image dimension
	ncols  = imgeti (imin, "i_naxis1")
	nlines = imgeti (imin, "i_naxis2")

	# Set output image pixel type the calulation data
	# type, instead of the input image data type
	call imputi (imout, "i_pixtype", TY_REAL)

	# Set lines before the subraster
	call ftr_linesetr (imin, imout, option, 1, yc - rmax - 1)

	# Set lines in the subraster
	do line = yc - rmax, yc + rmax {

	    # Fill columns nefore the subraster
	    call ftr_colsetr (imin, imout, option, line, 1, xc - rmax - 1)

	    # Compute columns within the subraster
	    do col = xc - rmax, xc + rmax {

		# Compute the radius, the pixel intensity for that point
		# in the input image, and the fitted value for that point.
		r    = sqrt (real ((xc - col) ** 2 + (yc - line) ** 2))
		func = Memr[imgl2r (imin, line) + col - 1]
		if (r <= rmax)
		    fit  = rcveval (cv, r)

		# Branch on output option
		switch (option) {
		case OPT_FIT:
		    if (r <= rmax)
			Memr[impl2r (imout, line) + col - 1] = fit
		    else
			Memr[impl2r (imout, line) + col - 1] = func
		case OPT_DIFFERENCE:
		    if (r <= rmax)
			Memr[impl2r (imout, line) + col - 1] = func - fit
		    else
			Memr[impl2r (imout, line) + col - 1] = real (0)
		case OPT_RATIO:
		    if (r <= rmax) {
			if (fit != 0.0001)
			    Memr[impl2r (imout, line) + col - 1] = func / fit
			else
			    Memr[impl2r (imout, line) + col - 1] = 0
		    } else
			Memr[impl2r (imout, line) + col - 1] = real (1)
		default:
		    call error (0, "Unknown output option (ftr_lineset)")
		}
	    }

	    # Fill columns after the subraster
	    call ftr_colsetr (imin, imout, option, line, xc + rmax + 1, ncols)
	}

	# Set lines after the subraster
	call ftr_linesetr (imin, imout, option, yc + rmax + 1, nlines)
end


# FTR_LINESET -- Set output image lines from input image lines, depending
# on the output option.

procedure ftr_linesetr (imin, imout, option, lstart, lend)

pointer	imin				# IMIO descriptor for input image
pointer	imout				# IMIO descriptor for output image
int	lstart, lend			# starting and ending lines
int	option				# output option

int	line, npix

int	imgeti()
pointer	imgl2r(), impl2r()

begin
	# Get line length
	npix = imgeti (imin, "i_naxis1")

	# Set lines in range
	do line = lstart, lend  {
	    switch (option) {
	    case OPT_FIT:
		call amovr (Memr[imgl2r (imin, line)],
			     Memr[impl2r (imout, line)],
			     npix)
	    case OPT_DIFFERENCE:
		call aclrr (Memr[impl2r (imout, line)], npix)
	    case OPT_RATIO:
		call amovkr (real (1), Memr[impl2r (imout, line)], npix)
	    default:
		call error (0, "Unknown output option (ftr_lineset)")
	    }
	}
end


# FTR_COLSET -- Set output image columns from input image lines, for a
# given line, depending on the output option.

procedure ftr_colsetr (imin, imout, option, line, cstart, cend)

pointer	imin				# IMIO descriptor for input image
pointer	imout				# IMIO descriptor for output image
int	option				# output option
int	line				# line number
int	cstart, cend			# starting and ending columns

int	npix

pointer	imgl2r(), impl2r()

begin
	# Compute number of pixels to set
	npix = cend - cstart + 1
	if (npix == 0)
	    return

	# Set colums in range
	switch (option) {
	case OPT_FIT:
	    call amovr (Memr[imgl2r (imin, line) + cstart - 1],
			 Memr[impl2r (imout, line) + cstart - 1],
			 npix)
	case OPT_DIFFERENCE:
	    call aclrr (Memr[impl2r (imout, line) + cstart - 1], npix)
	case OPT_RATIO:
	    call amovkr (real (1),
			  Memr[impl2r (imout, line) + cstart - 1],
			  npix)
	default:
	    call error (0, "Unknown output option (ftr_colset)")
	}
end
