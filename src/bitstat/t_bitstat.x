include	<error.h>
include	<imhdr.h>
include	<mach.h>

# Format strings for title and data output
define	TITLE_FORMAT1	"\n%s%s, npix=%d\n\n"
define	TITLE_FORMAT2	"%3.3s  %10.10s  %10.10s  %5.5s  %5.5s\n"
define	TITLE_FORMAT3	"---  ----------  ----------  -----  -----\n"
define	TITLE_FORMAT4	"     ----------  ----------  -----  -----\n"
define	DATA_FORMAT1	"%3d  %10d  %10d  %5.1f  %5.1f\n"
define	DATA_FORMAT2	"     %10d  %10d  %5.1f  %5.1f\n"


# T_BITSTAT -- Make bit statistics over a list of images. The values of all
# bits in all pixels for each image are tested. Two sets of counters are
# mantained for each bit. If the bit value is '0' the corresponding counter
# in the "zero" set is incremented. Otherwise the "one" counter is incremented.
# In this way it is possible to check if the electronics of the CCD is working
# well, and there is no bit with preferences to a certain value.

procedure t_bitstat ()

char	name[SZ_FNAME]		# image name
char	output[SZ_FNAME]	# output file name
int	fd			# output file descriptor
pointer	list			# input image list
pointer	im

int	open()
int	imtgetim()
pointer	immap()
pointer	imtopenp()

begin
	# Get task parameters
	list = imtopenp ("images")
	call clgstr ("output", output, SZ_FNAME)

	# Open output file
	fd = open (output, NEW_FILE, TEXT_FILE)

	# Loop over input list
	while (imtgetim (list, name, SZ_FNAME) != EOF) {

	    # Open image
	    iferr (im = immap (name, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Process image
	    call bst_image (im, name, fd)

	    # Close image
	    call imunmap (im)
	}

	# Close all
	call close (fd)
	call imtclose (list)
end


# BST_IMAGE-- Make pixel statistics for a single image, and write the
# results into an output file.

procedure bst_image (im, name, fd)

pointer	im			# input image descriptor
char	name[ARB]		# input image name
int	fd			# output file descriptor

char	pixstr[SZ_LINE]		# pixel type string
int	pixtype			# pixel type
int	bit			# bit counter
int	maxbits			# max number of bits
int	npix			# line length
long	totpix			# total number of pixels
long	totzero, totone		# total number of "0" and "1"
long	v[IM_MAXDIM]		# line counter
long	zero[NBITS_INT]		# "0" counter
long	one[NBITS_INT]		# "1" counter
pointer	lineptr			# line pointer

int	imgeti()
int	imgnls(), imgnli(), imgnll()
int	bst_npix()
errchk	imgnls(), imgnli(), imgnll(), imgeti()

begin
	# Get image line length and type
	npix    = imgeti (im, "i_naxis1")
	pixtype = imgeti (im, "i_pixtype")

	# Clear counters
	call amovkl (long (1), v, IM_MAXDIM)
	call aclrl (zero, NBITS_INT)
	call aclrl (one,  NBITS_INT)

	# Test pixel type and set number of bits to process
	switch (pixtype) {
	case TY_SHORT:
	    maxbits = NBITS_SHORT
	    while (imgnls (im, lineptr, v) != EOF)
		call bst_lines (Mems[lineptr], npix, maxbits, zero, one)

	case TY_USHORT:
	    maxbits = NBITS_SHORT
	    while (imgnli (im, lineptr, v) != EOF)
		call bst_linei (Memi[lineptr], npix, maxbits, zero, one)

	case TY_INT:
	    maxbits = NBITS_INT
	    while (imgnli (im, lineptr, v) != EOF)
		call bst_linei (Memi[lineptr], npix, maxbits, zero, one)

	case TY_LONG:
	    maxbits = NBITS_INT
	    while (imgnll (im, lineptr, v) != EOF)
		call bst_linel (Meml[lineptr], npix, maxbits, zero, one)

	default:
	    call error (0, "Image data type not short, ushort, integer, or long")
	}

	# Get total number of pixels and the pixel type as a string.
	# All of them are used in the output title.
	totpix = bst_npix (im)
	call bst_pixtype (im, pixstr, SZ_LINE)

	# Initialize counters
	totzero = 0
	totone  = 0

	# Write counters to the output file
	call fprintf (fd, TITLE_FORMAT1)
	    call pargstr (name)
	    call pargstr (pixstr)
	    call pargi   (totpix)
	call fprintf (fd, TITLE_FORMAT2)
	    call pargstr ("bit")
	    call pargstr ("0's")
	    call pargstr ("1's")
	    call pargstr ("%0's")
	    call pargstr ("%1's")
	call fprintf (fd, TITLE_FORMAT3)
	do bit = 1, maxbits {
	    call fprintf (fd, DATA_FORMAT1)
		call pargi (bit - 1)
		call pargl (zero[bit])
		call pargl (one[bit])
		call pargr (real (zero[bit] * 100 / totpix))
		call pargr (real (one[bit]  * 100 / totpix))
	    totone  = totone + one[bit]
	    totzero = totzero + zero[bit]
	}
	call fprintf (fd, TITLE_FORMAT4)
	call fprintf (fd, DATA_FORMAT2)
	    call pargl (totzero)
	    call pargi (totone)
	    call pargr (real (totzero * 100) / real (totzero + totone))
	    call pargr (real (totone  * 100) / real (totzero + totone))
	call flush (fd)
end


# BST_NPIX -- Compute the total number of pixels in the input image, and
# the image section that was processed.

long procedure bst_npix (im)

pointer	im			# input image descriptor

int	i
long	npix
char	str[SZ_LINE]

int	imgeti()

begin
	# Initialize output parameters
	npix = imgeti (im, "i_naxis1")

	# Loop over all images axes
	do i = 2, imgeti (im, "i_naxis") {
	    call sprintf (str, SZ_LINE, "i_naxis%d")
		call pargi (i)
	    npix = npix * imgeti (im, str)
	}
	return (npix)
end


# BST_PIXTYPE -- Get pixel type as a string value.

procedure bst_pixtype (im, pixtype, maxch)

pointer	im			# input image descriptor
char	pixtype[maxch]		# image pixel type string (output)
int	maxch			# max number of characters in string

int	imgeti()

begin
	# Branch on pixel type
	switch (imgeti (im, "i_pixtype")) {
	case TY_USHORT:
	    call strcpy ("[ushort]", pixtype, maxch)
	case TY_SHORT:
	    call strcpy ("[short]", pixtype, maxch)
	case TY_INT:
	    call strcpy ("[int]", pixtype, maxch)
	case TY_LONG:
	    call strcpy ("[long]", pixtype, maxch)
	case TY_REAL:
	    call strcpy ("[real]", pixtype, maxch)
	case TY_DOUBLE:
	    call strcpy ("[double]", pixtype, maxch)
	case TY_COMPLEX:
	    call strcpy ("[complex]", pixtype, maxch)
	default:
	    call strcpy ("unknown", pixtype, maxch)
	}
end
