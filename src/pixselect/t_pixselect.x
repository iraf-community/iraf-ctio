include	<error.h>


# T_PIXSELECT -- Select pixels within a certain range, and print them to
# the standard output. The output format is the same as the LISTPIXELS
# task.

procedure t_pixselect ()

char	image[SZ_FNAME]			# image name
real	lower				# lower limit of window
real	upper				# upper limit of window
bool	verbose				# verbose output
int	pixtype				# image pixel type
pointer	imlist				# image list
pointer	im				# image descriptor

bool	clgetb()
int	imgeti(), imtgetim()
real	clgetr()
pointer	imtopenp(), immap()

begin
	# Get parameters
	imlist  = imtopenp ("images")
	lower   = clgetr ("lower")
	upper   = clgetr ("upper")
	verbose = clgetb ("verbose")

	# Replace the pixels in each image.  Optimize IMIO.
	while (imtgetim (imlist, image, SZ_FNAME) != EOF) {

	    # Print banner string.
	    if (verbose) {
		call printf ("\n#Image: %s\n\n")
		call pargstr (image)
	    }

	    # Open input image
	    iferr (im = immap (image, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Branch on image pixel type
	    pixtype = imgeti (im, "i_pixtype")
	    switch (pixtype) {
	    case TY_SHORT:
		call pixselects (im, lower, upper)
	    case TY_USHORT, TY_INT:
		call pixselecti (im, lower, upper)
	    case TY_LONG:
		call pixselectl (im, lower, upper)
	    case TY_REAL:
		call pixselectr (im, lower, upper)
	    case TY_DOUBLE:
		call pixselectd (im, lower, upper)
	    case TY_COMPLEX:
		call pixselectx (im, lower, upper)
	    default:
		call error (0, "Unsupported image pixel datatype")
	    }

	    # Unmap image
	    call imunmap (im)
	}

	# Close image list
	call imtclose (imlist)
end
