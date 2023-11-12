include	<error.h>
include	<mach.h>
include	"iraf2bin.h"


# T_IRAF2BIN -- Convert a list of iraf images binary files into binary files.

procedure t_iraf2bin ()

char	fname[SZ_FNAME]		# file name
char	imname[SZ_FNAME]	# image name
char	str[SZ_LINE]
bool	header			# write header ?
int	swap			# swap mode
int	flist			# file list
int	ftype			# file data type
int	ndim, nlines, ncols	# image dimension
int	fd			# file descriptor
pointer	imlist			# image list
pointer	im			# image descriptor

bool	clgetb()
int	clgwrd()
int	clpopni(), clgfil()
int	open()
int	imgeti()
int	imtgetim()
pointer	immap()
pointer	imtopenp()

begin
	# Get parameters
	imlist = imtopenp ("images")
	flist  = clpopni  ("files")
	ftype  = clgwrd   ("data_type", str, SZ_LINE, OUTPUT_TYPES)
	swap   = clgwrd   ("swap", str, SZ_LINE, SWAP_MODES)
	header = clgetb   ("header")

	# Loop over files in the input list
	while (imtgetim (imlist, imname, SZ_FNAME) != EOF) {

	    # Open input image
	    iferr (im = immap (imname, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get image dimensions
	    ndim = imgeti (im, "i_naxis")
	    if (ndim < 1 || ndim > 2) {
		call eprintf ("Image %s is not one or two dimensional\n")
		    call pargstr (imname)
	    } else if (ndim == 2)
	        nlines = imgeti (im, "i_naxis2")
	    else
		nlines = 1
	    ncols  = imgeti (im, "i_naxis1")

	    # Check swapping mode against number of columns
	    if (swap == SWAP_2 && mod (ncols, 2) != 0) {
		call eprintf ("Number of columns must be a multiple of two")
		next
	    } else if (swap == SWAP_4 && mod (ncols, 4) != 0) {
		call eprintf ("Number of columns must be a multiple of four")
		next
	    }

	    # Get file name and open it
	    if (clgfil (flist, fname, SZ_FNAME) != EOF) {
		iferr (fd = open (fname, NEW_FILE, BINARY_FILE)) {
		    call erract (EA_WARN)
		    next
		}
	    } else {
		call eprintf ("File list shorter than image list")
		break
	    }

	    # Write output header if necessary
	    if (header)
		call i2b_header (fd, ncols, nlines, swap)

	    # Get pixel data type against output data type
	    switch (imgeti (im, "i_pixtype")) {
	    case TY_SHORT:
		call i2b_procs (im, imname, ncols, nlines, fd, ftype, swap)
	    case TY_USHORT, TY_INT:
		call i2b_proci (im, imname, ncols, nlines, fd, ftype, swap)
	    case TY_LONG:
		call i2b_procl (im, imname, ncols, nlines, fd, ftype, swap)
	    case TY_REAL:
		call i2b_procr (im, imname, ncols, nlines, fd, ftype, swap)
	    case TY_DOUBLE:
		call i2b_procd (im, imname, ncols, nlines, fd, ftype, swap)
	    default:
		call eprintf ("Unsupported pixel type for %s\n")
		    call pargstr (imname)
		next
	    }

	    # Close image and file
	    call imunmap (im)
	    call close (fd)
	}

	# Close lists
	call clpcls (flist)
	call clpcls (imlist)
end


# I2B_HEADER -- Write header into the output file. The header consists
# of an integer  buffer whose size (in bytes) is four times the number of
# columns. The first two positions contain the number of columns and the
# number of lines, respectively.

procedure i2b_header (fd, ncols, nlines, swap)

int	fd			# output file descriptor
int	ncols			# number of columns
int	nlines			# number of nlines
int	swap			# swap mode

int	npix, nchars, nbytes
pointer	hbuf, sbuf, sp

begin
	# Determine buffer size in different units
	nbytes = ncols * 4
	nchars = nbytes / SZB_CHAR
	npix   = nchars / SZ_INT32

	# Allocate header buffer
	call smark  (sp)
	call salloc (hbuf, npix, TY_INT)
	call salloc (sbuf, npix, TY_INT)
	if (swap != SWAP_NONE)
	    call salloc (sbuf, npix, TY_INT)

	# Enter number of lines and columns into the buffer
	Memi[hbuf + 0] = ncols
	Memi[hbuf + 1] = nlines

	# Swap bytes, if necessary. The swap buffer pointer will
	# point to the read buffer if no swapping was selected.
	switch (swap) {
	case SWAP_NONE:
	    sbuf = hbuf
	case SWAP_2:
	    call bswap2 (Memi[hbuf], 1, Memi[sbuf], 1, nbytes)
	case SWAP_4:
	    call bswap4 (Memi[hbuf], 1, Memi[sbuf], 1, nbytes)
	default:
	    call error (0, "i2b_header: unknown swap mode")
	}

	# Write buffer to the file
	call ipak32 (Memi[sbuf], Memi[sbuf], npix)
	call write (fd, Memi[sbuf], nchars)

	# Free memory
	call sfree (sp)
end
