include	<error.h>
include	<mach.h>

# Input data types
define	INPUT_TYPES	"|ubyte|ushort|short|int|long|real|"
define	INPUT_UBYTE	1
define	INPUT_USHORT	2
define	INPUT_SHORT	3
define	INPUT_INT	4
define	INPUT_LONG	5
define	INPUT_REAL	6

# Swap modes
define	SWAP_MODES	"|none|swap2|swap4|"
define	SWAP_NONE	1
define	SWAP_2		2
define	SWAP_4		3


# T_BIN2IRAF -- Convert a list of binary files into one or two dimensional
# IRAF images.

procedure t_bin2iraf ()

char	fname[SZ_FNAME]		# file name
char	imname[SZ_FNAME]	# image name
char	str[SZ_LINE]
int	swap			# swap mode
int	flist, imlist		# file and image lists
int	ftype, imtype		# file and image data types
int	nlines, ncols		# image dimension
int	nskip			# number of header bytes to skip
int	fd			# file descriptor
pointer	im			# image descriptor

int	clgeti(), clgwrd()
int	clpopni(), clgfil()
int	open()
pointer	immap()

begin
	# Get parameters
	flist  = clpopni ("files")
	imlist = clpopni ("images")
	ncols  = clgeti  ("ncols")
	nlines = clgeti  ("nlines")
	nskip  = clgeti  ("nskip")
	swap   = clgwrd  ("swap", str, SZ_LINE, SWAP_MODES)

	# Determine the input and output data types
	switch (clgwrd  ("data_type", str, SZ_LINE, INPUT_TYPES)) {
	case INPUT_UBYTE:
	    ftype  = TY_UBYTE
	    imtype = TY_SHORT
	case INPUT_USHORT:
	    ftype  = TY_USHORT
	    imtype = TY_USHORT
	case INPUT_SHORT:
	    ftype  = TY_SHORT
	    imtype = TY_SHORT
	case INPUT_INT:
	    ftype  = TY_INT
	    imtype = TY_INT
	case INPUT_LONG:
	    ftype  = TY_LONG
	    imtype = TY_LONG
	case INPUT_REAL:
	    ftype  = TY_REAL
	    imtype = TY_REAL
	default:
	    call error (0, "Unknown input data type")
	}

	# Check number of bytes to skip against the size of a char
	if (mod (nskip, SZB_CHAR) != 0) {
	    call sprintf (str, SZ_LINE,
			  "Number of bytes to skip must be a multiple of %d")
		call pargi (SZB_CHAR)
	    call error (0, str)
	}

	# Check swapping mode against number of columns
	if (swap == SWAP_2 && mod (ncols, 2) != 0)
	    call error (0, "Number of columns must be a multiple of two")
	else if (swap == SWAP_4 && mod (ncols, 4) != 0)
	    call error (0, "Number of columns must be a multiple of four")

	# Loop over files in the input list
	while (clgfil (flist, fname, SZ_FNAME) != EOF) {

	    # Open input file
	    iferr (fd = open (fname, READ_ONLY, BINARY_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Get image name and open it
	    if (clgfil (imlist, imname, SZ_FNAME) != EOF) {
		iferr (im = immap (imname, NEW_IMAGE, 0)) {
		    call erract (EA_WARN)
		    next
		}
	    } else {
		call eprintf ("File list shorter then image list")
		break
	    }

	    # Update image header
	    if (nlines > 1) {
	        call imputi (im, "i_naxis",  2)
		call imputi (im, "i_naxis2", nlines)
	    } else
		call imputi (im, "i_naxis", 1)
	    call imputi (im, "i_naxis1",  ncols)
	    call impstr (im, "i_title",   fname)
	    call imputi (im, "i_pixtype", imtype)

	    # Process file
	    call bin2iraf (fd, fname, im, nlines, ncols, nskip,
			   ftype, imtype, swap)

	    # Close file and image
	    call close (fd)
	    call imunmap (im)
	}

	# Close lists
	call clpcls (flist)
	call clpcls (imlist)
end


# BIN2IRAF -- Convert a single binary file into an image. Data is read from
# the file into a character buffer, then bytes are swapped if necessary,
# and finally converted to the appropiate pixel type before writing them
# to the image.

procedure bin2iraf (fd, fname, im, nlines, ncols, nskip, ftype, imtype, swap)

int	fd			# file descriptor
char	fname[ARB]		# file name (error report only)
pointer	im			# image descriptor
int	nlines, ncols		# image dimension
int	nskip			# number of header bytes to skip
int	ftype			# input file data type
int	imtype			# output image pixel type
int	swap			# swap mode

int	line
int	nbytes, nchars, nread
pointer	readbuf, swapbuf, linebuf
pointer	sp

int	read()
pointer	impl1l(), impl2l()
pointer	impl1r(), impl2r()
errchk	read(), seek()

include <szpixtype.inc>

begin
	# Determine the number of characters to read from
	# the file, based on the file data type
	if (ftype == TY_UBYTE) {
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	} else {
	    nchars = ncols * pix_size[ftype]
	    nbytes = nchars * SZB_CHAR
	}

	# Skip bytes at the beginning. The offset for the beggining
	# of the file is one and not zero.
	if (nskip > 0)
	    call seek (fd, long (nskip / SZB_CHAR + 1))

	# Allocate read, swap, and line buffers. The swap buffer
	# is only allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (readbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)
	if (imtype == TY_REAL)
	    call salloc (linebuf, ncols, TY_REAL)
	else
	    call salloc (linebuf, ncols, TY_LONG)

	# Loop reading from input file
	do line = 1, nlines {

	    # Read one line
	    nread = read (fd, Memc[readbuf], nchars)

	    # Check if the read was sucessfull, and if so,
	    # convert the line read into the appropiate type.
	    # Byte swaping is done before the conversion.
	    if (nread == EOF) {
		call eprintf ("%s: EOF encountered at line %d")
		    call pargstr (fname)
		    call pargi   (line)
		break

	    } else if (nread != nchars) {
		call eprintf ("%s: Incomplete line (%d pixels) at line %d\n")
		    call pargstr (fname)
		    if (ftype == TY_UBYTE)
		        call pargi (nread * SZB_CHAR)
		    else
		        call pargi (int (nread / pix_size[ftype]))
		    call pargi (line)
		break

	    } else {

		# Swap bytes, if necessary. The swap buffer pointer will
		# point to the read buffer if no swapping was selected.
		switch (swap) {
		case SWAP_NONE:
		    swapbuf = readbuf
		case SWAP_2:
		    call bswap2 (Memc[readbuf], 1, Memc[swapbuf], 1, nbytes)
		case SWAP_4:
		    call bswap4 (Memc[readbuf], 1, Memc[swapbuf], 1, nbytes)
		default:
		    call error (0, "bin2iraf: unknown swap mode")
		}

		# Convert buffer into image line, and write it
		switch (imtype) {
		    case TY_SHORT, TY_USHORT, TY_INT, TY_LONG:
			switch (ftype) {
			case TY_UBYTE:
			    call achtbl (Memc[swapbuf], Meml[linebuf], ncols)
			case TY_SHORT:
			    call achtsl (Memc[swapbuf], Meml[linebuf], ncols)
			case TY_USHORT:
			    call achtul (Memc[swapbuf], Meml[linebuf], ncols)
			case TY_INT:
			    call achtil (Memc[swapbuf], Meml[linebuf], ncols)
			case TY_LONG:
			    call achtll (Memc[swapbuf], Meml[linebuf], ncols)
			default:
			    call error (0, "bin2iraf: illegal file type (i)")
			}
			if (nlines == 1)
			    call amovl (Meml[linebuf], Meml[impl1l (im)],
					ncols)
			else
			    call amovl (Meml[linebuf], Meml[impl2l (im, line)],
					ncols)
		    case TY_REAL:
			if (ftype == TY_REAL)
			    call achtrr (Memc[swapbuf], Memr[linebuf], ncols)
			else
			    call error (0, "bin2iraf: illegal file type (r)")
			if (nlines == 1)
			    call amovr (Memr[linebuf], Memr[impl1r (im)],
					ncols)
			else
			    call amovr (Memr[linebuf], Memr[impl2r (im, line)],
					ncols)
		    default:
			call error (0, "bin2iraf: unknown image type")
		}
	    }
	}

	# Free memory
	call sfree (sp)
end
