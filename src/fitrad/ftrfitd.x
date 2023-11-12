include	"fitrad.h"

# Map procedure name
define	icg_fitr	icg_fit


# FTR_FIT -- Fit a radial profile to an image.

procedure ftr_fitd (imin, imout, ic, gt, title, xcenter, ycenter, radius,
		     option, ringavg, minwidth, minpts, interactive, verbose)

pointer	imin				# IMIO descriptor for input image
pointer	imout				# IMIO descriptor for output image
pointer	ic				# ICFIT pointer
pointer	gt				# GTOOLS pointer
char	title[ARB]			# title
real	xcenter, ycenter		# subraster center coordinates
real	radius				# subraster radius
int	option				# output option
int	ringavg				# averaging method
real	minwidth			# minimum ring width
int	minpts				# minimum number of points in a ring
bool	interactive			# interactive fit ?
bool	verbose				# verbose ?

char	graphics[SZ_FNAME]		# graphics device
int	i, j
int	nlines, npix, npts
int	xc, yc, rmax
double	r
pointer	x, y, wts
pointer	gp, cv
pointer	sp

int	imgeti()
pointer	gopen()
pointer	imgl2d()
errchk	icg_fit(), icg_fitd()

begin
	# Get image number of lines and pixels per line
	npix = imgeti (imin, "i_naxis1")
	nlines = imgeti (imin, "i_naxis2")

	# Convert center coordinates and radius to integer, in
	# order to have integer indices to access the subraster,
	# and set default values if they are undefined or out of range
	if (IS_INDEFR (xcenter) || xcenter < 1 || xcenter > npix)
	    xc = int (max (1, npix / 2))
	else
	    xc = int (xcenter + 0.5)
	if (IS_INDEFR (ycenter) || ycenter < 1 || ycenter > nlines)
	    yc = int (max (1, nlines / 2))
	else
	    yc = int (ycenter + 0.5)
	i = min (xc - 1, yc - 1, npix - xc, nlines - yc)
	if (IS_INDEFR (radius) || radius < 1 || radius > i)
	    rmax = max (1, i)
	else
	    rmax = int (radius + 0.5)

	# Allocate and initialize memory for curve fitting.
	npts = 4 * rmax * rmax
	call smark (sp)
	call salloc (x, npts, TY_DOUBLE)
	call salloc (y, npts, TY_DOUBLE)
	call salloc (wts, npts, TY_DOUBLE)
	call amovkd (1.0, Memr[wts], npts)

	# Verbose
	if (verbose) {
	    call printf ("..reading input image\n")
	    call flush (STDOUT)
	}

	# Read image lines and compute the radius for each pixel in a
	# line. Enter the radius in the X buffer, and the pixel value
	# into the Y buffer, if the radius is within the desired subraster.
	npts = 0
	do i = yc - rmax, yc + rmax {
	    do j = xc - rmax, xc + rmax {
		r = sqrt (double ((xc - j) ** 2 + (yc - i) ** 2))
		if (r <= rmax) {
		    Memd[x + npts] = r
		    Memd[y + npts] = Memd[imgl2d (imin, i) + j - 1]
		    npts = npts + 1
		}
	    }
	}

	# Check number of points for fit
	if (npts == 0)
	    call error (0, "No points for fit")

	# Verbose
	if (verbose) {
	    call printf ("..sorting data\n")
	    call flush (STDOUT)
	}

	# Sort data
	call ftr_sortd (Memd[x], Memd[y], npts)

	# Verbose
	if (verbose) {
	    call printf ("..averaging data\n")
	    call flush (STDOUT)
	}

	# Average data points
	call ftr_averaged (Memd[x], Memd[y], npts, minwidth, minpts, ringavg)

	# Set ICFIT minimum and maximum values
	call ic_putr (ic, "xmin", Memd[x])
	call ic_putr (ic, "xmax", Memd[x + npts - 1])

	# Verbose
	if (verbose) {
	    call printf ("..fitting data points\n")
	    call flush (STDOUT)
	}

	# Fit either interactively or non-interactively
	if (interactive) {

	    # Open graphics device
	    call clgstr ("graphics", graphics, SZ_FNAME)
	    gp = gopen (graphics, NEW_FILE, STDGRAPH)

	    # Fit interactively
	    call icg_fitd (ic, gp, "cursor", gt, cv, Memd[x], Memd[y],
			    Memd[wts], npts)

	    # Close graphics device
	    call gclose (gp)

	} else 
	    call ic_fitd (ic, cv, Memd[x], Memd[y], Memd[wts], npts,
			    YES, YES, YES, YES)

	# Verbose
	if (verbose) {
	    call printf ("..writing output image\n")
	    call flush (STDOUT)
	}

	# Output data
	call ftr_outputd (imin, imout, cv, option, xc, yc, rmax) 

	# Free memory
	call sfree (sp)
end
