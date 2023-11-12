include	<error.h>
include <pkg/gtools.h>
include	"fitrad.h"


# T_FITRAD - Fit a function to circular image subrasters, and output an image
# consisting of the fit, the difference, or the ratio. The fitting parameters
# may be set interactively using the ICFIT package.

procedure t_fitrad ()

bool	interactive			# interactive ?
bool	verbose				# vebose processing ?
char	outroot[SZ_LINE]		# output image root
char	function[SZ_LINE]		# fitting function
char	dummy[SZ_LINE]
int	inlist				# input image list
int	option				# output option
int	ringavg				# ring averaging method
int	minpts				# minimum number of point when averaging
int	niterate			# number of rejection iterations
int	order				# function order
int	calctype			# calculation type (real, double)
real	xcenter, ycenter		# subraster center coordinates
real	radius				# subraster radius
real	minwidth			# minimum ring width when averaging
real	low_reject, high_reject		# rejection limits
real	grow				# rejection growing radius

char	input[SZ_LINE]			# Input image
char	output[SZ_FNAME]		# Output image
pointer	imin, imout				# IMIO pointers
pointer	ic				# ICFIT pointer
pointer	gt				# GTOOLS pointer

bool	clgetb()
bool	strne()
int	clgeti(), clgwrd()
int	imgeti()
int	imtopenp(), imtgetim()
int	gt_init()
real	clgetr()
pointer	immap()

begin
	# Get task parameters
	inlist = imtopenp ("images")
	call clgstr ("outroot", outroot, SZ_LINE)
	option = clgwrd ("option", dummy, SZ_LINE, OPTIONS)
	xcenter = clgetr ("xcenter")
	ycenter = clgetr ("ycenter")
	radius = clgetr ("radius")
	ringavg = clgwrd ("ringavg", dummy, SZ_LINE, RINGAVG)
	minpts = clgeti ("minpts")
	minwidth = clgetr ("minwidth")
	calctype = clgwrd ("calctype", dummy, SZ_LINE, CALTYPES)
	verbose = clgetb ("verbose")

	# Get ICFIT parameters
	call clgstr ("function", function, SZ_LINE)
	order = clgeti ("order")
	low_reject = clgetr ("low_reject")
	high_reject = clgetr ("high_reject")
	niterate = clgeti ("niterate")
	grow = clgetr ("grow")
	interactive = clgetb ("interactive")

	# Check parameter concistencies
	if (option == 0)
	    call error (0, "Unknown output option")
	if (ringavg == 0)
	    call error (0, "Unknown ring averaging method")
	if (IS_INDEFR (minwidth) && IS_INDEFI (minpts))
	    call error (0, "'minwidth' and 'minpts' are both undefined")

	# Initialize ICFIT pointer structure.
	call ic_open (ic)
	call ic_pstr (ic, "function", function)
	call ic_puti (ic, "order", order)
	call ic_putr (ic, "low", low_reject)
	call ic_putr (ic, "high", high_reject)
	call ic_puti (ic, "niterate", niterate)
	call ic_putr (ic, "grow", grow)
	call ic_pstr (ic, "xlabel", "radius")
	call ic_pstr (ic, "ylabel", "counts")

	# Initialize GTOOLS
	gt = gt_init()

	# Fit the lines in each input image.
	while (imtgetim (inlist, input, SZ_LINE) != EOF)  {

	    # Open input image
	    iferr (imin = immap (input, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Check input image dimension
	    if (imgeti (imin, "i_naxis") > 2) {
	        call eprintf (
		    "Warning: Image dimensions > 2 are not implemented\n")
		call imunmap (imin)
		next
	    }

	    # Build output image name
	    if (strne (outroot, "")) {
		call sprintf (output, SZ_LINE, "%s%s")
		    call pargstr (outroot)
		    call pargstr (input)
	    } else {
		call sprintf (output, SZ_LINE, "out.%s")
		    call pargstr (input)
	    }

	    # Open output image
	    iferr (imout = immap (output, NEW_COPY, imin)) {
		call erract (EA_WARN)
		call imunmap (imin)
		next
	    }

	    # Put image title in graph title
	    iferr {
		call imgstr (imin, "i_title", dummy, SZ_LINE)
		call gt_sets (gt, GTTITLE, dummy)
	    } then
		call erract (EA_WARN)

	    # Verbose
	    if (verbose) {
		call printf ("Input: %s, Output: %s\n")
		    call pargstr (input)
		    call pargstr (output)
		call flush (STDOUT)
	    }

	    # Process image
	    if (calctype == CTY_REAL) {
		iferr (call ftr_fitr (imin, imout, ic, gt, input,
				 xcenter, ycenter, radius,
				 option, ringavg, minwidth, minpts,
				 interactive, verbose))
		    call erract (EA_WARN)
	    } else {
		iferr (call ftr_fitd (imin, imout, ic, gt, input,
				 xcenter, ycenter, radius,
				 option, ringavg, minwidth, minpts,
				 interactive, verbose))
		    call erract (EA_WARN)
	    }

	    # Close images
	    call imunmap (imin)
	    call imunmap (imout)
	}

	# Close all
	call ic_closer (ic)
	call gt_free (gt)
	call imtclose (inlist)
end
