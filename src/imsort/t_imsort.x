include	<error.h>


# T_IMSORT - Sort a list of images by a given header parameter

procedure t_imsort ()

bool	invert			# invert sort ?
bool	verbose			# verbose output ?
char	image[SZ_FNAME]		# input image name
char	parameter[SZ_LINE]	# sorting parameter
char	strval[SZ_LINE]
int	imlist			# input image list

int	parlen, imlen		# string lengths
pointer	im			# image descriptor
pointer	ptr

include	"imsort.com"

bool	clgetb()
int	clpopnu(), clgfil(), clplen()
int	strlen()
pointer	immap()
pointer	srt_init(), srt_put()
int	ims_compare()

begin
	# Get parameters
	imlist = clpopnu ("images")
	call clgstr ("parameter", parameter, SZ_LINE)
	numeric = clgetb ("numeric")
	invert = clgetb ("invert")
	verbose = clgetb ("verbose")
	
	# Initialize sort
	sd = srt_init (clplen (imlist))

	# Loop over input list
	while (clgfil (imlist, image, SZ_FNAME) != EOF) {

	    # Try to ope image
	    iferr (im = immap (image, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get string parameter value
	    iferr (call imgstr (im, parameter, strval, SZ_LINE)) {
		call imunmap (im)
		call erract (EA_WARN)
		next
	    }

	    # Compute image name and parameter value lengths
	    imlen = strlen (image)
	    parlen = strlen (strval)

	    # Put value and image name
	    ptr = srt_put (sd, parlen + imlen + 2)
	    call sprintf (Memc[P2C(ptr)], parlen + imlen + 2, "%s %s")
		call pargstr (strval)
		call pargstr (image)
	    Memc[P2C (ptr) + parlen] = EOS

	    # Close image
	    call imunmap (im)
	}

	# Close input list
	call clpcls (imlist)

	# Sort
	call srt_sort (sd, ims_compare)

	# Print image names and values
	call ims_print (sd, invert, verbose)

	# Free sort descriptor
	call srt_free (sd)
end


# IMS_PRINT -- Print sorted image names and parameter values

procedure ims_print (sd, invert, verbose)

pointer	sd			# sort descriptor
bool	invert			# invert sort ?
bool	verbose			# verbose output ?

int	i, offset
pointer	ptr

int	strlen()
int	srt_nput()
pointer	srt_get ()

begin
	# Goto starting point
	if (invert)
	    call srt_tail (sd)
	else
	    call srt_head (sd)

	# Print all entries
	do i = 1, srt_nput (sd) {

	    # Get pointer to structure, and compute
	    # the length of the parameter value to use
	    # it as offset to get the image name.
	    ptr = srt_get (sd)
	    offset = strlen (Memc[P2C (ptr)])

	    # Check if verbose output is needed
	    if (verbose) {
	        call printf ("%s %s\n")
		    call pargstr (Memc[P2C (ptr) + offset + 1])
		    call pargstr (Memc[P2C (ptr)])
	    } else {
	        call printf ("%s\n")
		    call pargstr (Memc[P2C (ptr) + offset + 1])
	    }
	}
end


# IMS_COMPARE -- Comaprison function for srt_sort()

int procedure ims_compare (index1, index2)

int	index1, index2		# pointer indices

int	n, ip
double	val1, val2
pointer	ptr1, ptr2

include	"imsort.com"

int	ctod()
int	strcmp()
pointer	srt_ptr()

begin
	# Get pointers
	ptr1 = srt_ptr (sd, index1)
	ptr2 = srt_ptr (sd, index2)

	# Check whether a numeric or alphabetic sort is
	# neeeded. If the first case the strings are
	# converted to numbers, and if this is not possible,
	# they are assigend to an INDEF value.
	if (numeric) {

	    # Convert string to numeric values
	    ip = 1
	    if (ctod (Memc[P2C (ptr1)], ip, val1) == 0)
		val1 = INDEFD
	    ip = 1
	    if (ctod (Memc[P2C (ptr2)], ip, val2) == 0)
		val2 = INDEFD

	    # Compare them and return comparison value
	    if (val1 < val2)
		return (-1)
	    else if (val1 == val2)
		return (0)
	    else
		return (1)

	} else {

		# Compare strings directly
		n = strcmp (Memc[P2C (ptr1)], Memc[P2C (ptr2)])

		# Return comparison value
		if (n < 0)
		    return (-1)
		else if (n == 0)
		    return (0)
		else
		    return (1)
	}
end
