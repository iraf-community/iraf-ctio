include	<error.h>
include	<fset.h>
include <mach.h>

# Maximum number of characters in the image name in formatted output.
# If the image name is longer than this number no foratting is done
# and the image name is printed as it is. This number must be consistent
# with the numbers used in the verbose format string.
define	MAX_CHARS		30

# Output formats.
define	FORMAT_VERBOSE		"%-30.30s  %9d  %9d  %9d\n"
define	FORMAT_OVERFLOW		"%s  %9d  %9d  %9d\n"
define	FORMAT_NONVERBOSE	"%d  %d  %d\n"


# T_IMSPACE -- Determine the space used by the image header and the pixel
# file for a list of images, and give the total space used by them.

procedure t_imspace ()

bool	verbose			# verbose output ?
int	imlist			# input image list
int	imlen			# input image list length
long	hsize, psize		# header and pixel file sizes
long	htotal, ptotal		# header and pixel file totals
pointer	im			# image descriptor
pointer	header, pixfile		# file names
pointer	sp

bool	clgetb()
int	clpopnu(), clplen(), clgfil()
int	strlen()
pointer	immap()

begin
	# Get parameters
	imlist  = clpopnu ("images")
	verbose = clgetb  ("verbose")
	
	# Allocate string space
	call smark  (sp)
	call salloc (header,  SZ_FNAME, TY_CHAR)
	call salloc (pixfile, SZ_FNAME, TY_CHAR)

	# Initialize variables
	htotal = 0
	ptotal = 0
	imlen  = clplen (imlist)

	# Turn the verbose mode on if there is only one image in the
	# input list, so the individual file size will be printed
	# instead of the total.
	if (imlen == 1)
	    verbose = true

	# Loop over input list
	while (clgfil (imlist, Memc[header], SZ_FNAME) != EOF) {

	    # Open input image
	    iferr (im = immap (Memc[header], READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get pixel file name
	    iferr (call imgstr (im, "i_pixfile", Memc[pixfile], SZ_LINE)) {
		call erract  (EA_WARN)
		call imunmap (im)
		next
	    }

	    # Get header and pixel file sizes
	    call imsp_size (Memc[header], Memc[pixfile], hsize, psize)

	    # Print size of each individual file
	    if (verbose) {
		if (strlen (Memc[header]) > MAX_CHARS) {
		    call printf (FORMAT_OVERFLOW)
			call pargstr (Memc[header])
			call pargl (hsize)
			call pargl (psize)
			call pargl (hsize + psize)
		} else {
		    call printf (FORMAT_VERBOSE)
			call pargstr (Memc[header])
			call pargl (hsize)
			call pargl (psize)
			call pargl (hsize + psize)
		}
	    }

	    # Accumulate sizes
	    htotal = htotal + hsize
	    ptotal = ptotal + psize

	    # Close image and files
	    call imunmap (im)
	}

	# Print totals if there is more than one image in the input list
	if (imlen > 1) {
	    if (verbose) {
		call printf (FORMAT_VERBOSE)
		    call pargstr ("TOTAL")
		    call pargl (htotal)
		    call pargl (ptotal)
		    call pargl (htotal + ptotal)
	    } else {
		call printf (FORMAT_NONVERBOSE)
		    call pargl (htotal)
		    call pargl (ptotal)
		    call pargl (htotal + ptotal)
	    }
	}

	# Free memory
	call sfree (sp)

	# Close input image list
	call clpcls (imlist)
end


# IMSP_SIZE -- Determine the size of the header and the pixel files. The
# header file must be specified as a complete file name, e.g. the ".imh"
# extension must be present.

procedure imsp_size (header, pixfile, hsize, psize)

char	header[ARB]		# header file name
char	pixfile[ARB]		# pixel file name
long	hsize			# header file size (output)
long	psize			# pixel file size (output)

char	pname[SZ_FNAME]		# true pixel file name
int	hfd, pfd		# file descriptors
int	n, m

int	open()
int	strsearch(), strldxs()
long	fstatl()
errchk	open(), fstatl()

begin
	# Open the header file as a binary file
	hfd = open (header, READ_ONLY, BINARY_FILE)

	# Deal with the special case where the pixel file name
	# has the "HDR$" prefix. Prepend the path name of the
	# header to the pixel file name if one was specified.
	n = strsearch (pixfile, "HDR$")
	if (n > 0) {
	    m = strldxs ("/$", header)
	    if (m > 0) {
		call strcpy (header, pname, m)
		call strcat (pixfile[n], pname, SZ_FNAME)
	    } else
		call strcpy (pixfile[n], pname, SZ_FNAME)
	} else
	    call strcpy (pixfile, pname, SZ_FNAME)

	# Open the pixel file as a binary file
	iferr (pfd = open (pname, READ_ONLY, BINARY_FILE)) {
	    call close   (hfd)
	    call erract  (EA_ERROR)
	}

	# Determine file sizes in bytes
	hsize = fstatl (hfd, F_FILESIZE) * SZB_CHAR
	psize = fstatl (pfd, F_FILESIZE) * SZB_CHAR

	# Close files
	call close   (hfd)
	call close   (pfd)
end
