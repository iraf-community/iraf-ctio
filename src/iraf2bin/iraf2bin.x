include <mach.h>
include	"iraf2bin.h"


# IRAF2BIN -- Convert an image into a binary file. Data is read from
# the image line by line, then bytes are swapped if necessary, and finally
# written into the file.
# the file into a character buffer, then bytes are swapped if necessary,
# and finally converted to the appropiate pixel type before writing them
# to the image.



procedure i2b_procs (im, imname, ncols, nlines, fd, ftype, swap)

pointer	im				# image descriptor
int	ncols, nlines			# image dimensions
char	imname[ARB]			# image name (error report only)
int	fd				# file descriptor
int	ftype				# input file data type
int	swap				# swap mode

int	line
int	nbytes, nchars
pointer	linebuf, outbuf, swapbuf
pointer	sp

pointer	imgl2s()

include <szpixtype.inc>

begin
#call eprintf ("im=%d, imname=(%s), nc=%d, nl=%d, fd=%d, ft=%d, swap=%d\n")
#call pargi (im)
#call pargstr (imname)
#call pargi (ncols)
#call pargi (nlines)
#call pargi (fd)
#call pargi (ftype)
#call pargi (swap)

	# Determine the number of characters to write to the output
	# file, and the number of bytes to swap (if necessary).
	switch (ftype) {
	case OUTPUT_UBYTE:
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	case OUTPUT_SHORT, OUTPUT_USHORT:
	    nchars = ncols  * pix_size[TY_SHORT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_INT:
	    nchars = ncols  * pix_size[TY_INT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_LONG:
	    nchars = ncols  * pix_size[TY_LONG]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_REAL:
	    nchars = ncols  * pix_size[TY_REAL]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_DOUBLE:
	    nchars = ncols  * pix_size[TY_DOUBLE]
	    nbytes = nchars * SZB_CHAR
	default:
	    call error ("i2b_proc: Unknown output type")
	}

#call eprintf ("nc=%d, nb=%d\n")
#call pargi (nchars)
#call pargi (nbytes)

	# Allocate output and swap buffer. The swap buffer is only
	# allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (outbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)

	# Loop over all image lines
	do line = 1, nlines {

	    # Get image line buffer pointer
	    linebuf = imgl2s (im, line)

	    # Convert to the appropiate data type
	    switch (ftype) {
	    case OUTPUT_UBYTE:
		call achtsb (Mems[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_SHORT, OUTPUT_USHORT:
		call achtss (Mems[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_INT:
		call achtsi (Mems[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_LONG:
		call achtsl (Mems[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_REAL:
		call achtsr (Mems[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_DOUBLE:
		call achtsd (Mems[linebuf], Memc[outbuf], ncols)
	    default:
		call error ("i2b_proc: Unknown output type")
	    }

	    # Swap bytes, if necessary. The swap buffer pointer will
	    # point to the line buffer if no swapping was selected.
	    switch (swap) {
	    case SWAP_NONE:
		swapbuf = outbuf
	    case SWAP_2:
		call bswap2 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    case SWAP_4:
		call bswap4 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    default:
		call error (0, "i2b_proc: unknown swap mode")
	    }

	    # Write line into output file
	    call write (fd, Memc[swapbuf], nchars)
	}
end



procedure i2b_proci (im, imname, ncols, nlines, fd, ftype, swap)

pointer	im				# image descriptor
int	ncols, nlines			# image dimensions
char	imname[ARB]			# image name (error report only)
int	fd				# file descriptor
int	ftype				# input file data type
int	swap				# swap mode

int	line
int	nbytes, nchars
pointer	linebuf, outbuf, swapbuf
pointer	sp

pointer	imgl2i()

include <szpixtype.inc>

begin
#call eprintf ("im=%d, imname=(%s), nc=%d, nl=%d, fd=%d, ft=%d, swap=%d\n")
#call pargi (im)
#call pargstr (imname)
#call pargi (ncols)
#call pargi (nlines)
#call pargi (fd)
#call pargi (ftype)
#call pargi (swap)

	# Determine the number of characters to write to the output
	# file, and the number of bytes to swap (if necessary).
	switch (ftype) {
	case OUTPUT_UBYTE:
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	case OUTPUT_SHORT, OUTPUT_USHORT:
	    nchars = ncols  * pix_size[TY_SHORT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_INT:
	    nchars = ncols  * pix_size[TY_INT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_LONG:
	    nchars = ncols  * pix_size[TY_LONG]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_REAL:
	    nchars = ncols  * pix_size[TY_REAL]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_DOUBLE:
	    nchars = ncols  * pix_size[TY_DOUBLE]
	    nbytes = nchars * SZB_CHAR
	default:
	    call error ("i2b_proc: Unknown output type")
	}

#call eprintf ("nc=%d, nb=%d\n")
#call pargi (nchars)
#call pargi (nbytes)

	# Allocate output and swap buffer. The swap buffer is only
	# allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (outbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)

	# Loop over all image lines
	do line = 1, nlines {

	    # Get image line buffer pointer
	    linebuf = imgl2i (im, line)

	    # Convert to the appropiate data type
	    switch (ftype) {
	    case OUTPUT_UBYTE:
		call achtib (Memi[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_SHORT, OUTPUT_USHORT:
		call achtis (Memi[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_INT:
		call achtii (Memi[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_LONG:
		call achtil (Memi[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_REAL:
		call achtir (Memi[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_DOUBLE:
		call achtid (Memi[linebuf], Memc[outbuf], ncols)
	    default:
		call error ("i2b_proc: Unknown output type")
	    }

	    # Swap bytes, if necessary. The swap buffer pointer will
	    # point to the line buffer if no swapping was selected.
	    switch (swap) {
	    case SWAP_NONE:
		swapbuf = outbuf
	    case SWAP_2:
		call bswap2 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    case SWAP_4:
		call bswap4 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    default:
		call error (0, "i2b_proc: unknown swap mode")
	    }

	    # Write line into output file
	    call write (fd, Memc[swapbuf], nchars)
	}
end



procedure i2b_procl (im, imname, ncols, nlines, fd, ftype, swap)

pointer	im				# image descriptor
int	ncols, nlines			# image dimensions
char	imname[ARB]			# image name (error report only)
int	fd				# file descriptor
int	ftype				# input file data type
int	swap				# swap mode

int	line
int	nbytes, nchars
pointer	linebuf, outbuf, swapbuf
pointer	sp

pointer	imgl2l()

include <szpixtype.inc>

begin
#call eprintf ("im=%d, imname=(%s), nc=%d, nl=%d, fd=%d, ft=%d, swap=%d\n")
#call pargi (im)
#call pargstr (imname)
#call pargi (ncols)
#call pargi (nlines)
#call pargi (fd)
#call pargi (ftype)
#call pargi (swap)

	# Determine the number of characters to write to the output
	# file, and the number of bytes to swap (if necessary).
	switch (ftype) {
	case OUTPUT_UBYTE:
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	case OUTPUT_SHORT, OUTPUT_USHORT:
	    nchars = ncols  * pix_size[TY_SHORT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_INT:
	    nchars = ncols  * pix_size[TY_INT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_LONG:
	    nchars = ncols  * pix_size[TY_LONG]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_REAL:
	    nchars = ncols  * pix_size[TY_REAL]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_DOUBLE:
	    nchars = ncols  * pix_size[TY_DOUBLE]
	    nbytes = nchars * SZB_CHAR
	default:
	    call error ("i2b_proc: Unknown output type")
	}

#call eprintf ("nc=%d, nb=%d\n")
#call pargi (nchars)
#call pargi (nbytes)

	# Allocate output and swap buffer. The swap buffer is only
	# allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (outbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)

	# Loop over all image lines
	do line = 1, nlines {

	    # Get image line buffer pointer
	    linebuf = imgl2l (im, line)

	    # Convert to the appropiate data type
	    switch (ftype) {
	    case OUTPUT_UBYTE:
		call achtlb (Meml[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_SHORT, OUTPUT_USHORT:
		call achtls (Meml[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_INT:
		call achtli (Meml[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_LONG:
		call achtll (Meml[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_REAL:
		call achtlr (Meml[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_DOUBLE:
		call achtld (Meml[linebuf], Memc[outbuf], ncols)
	    default:
		call error ("i2b_proc: Unknown output type")
	    }

	    # Swap bytes, if necessary. The swap buffer pointer will
	    # point to the line buffer if no swapping was selected.
	    switch (swap) {
	    case SWAP_NONE:
		swapbuf = outbuf
	    case SWAP_2:
		call bswap2 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    case SWAP_4:
		call bswap4 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    default:
		call error (0, "i2b_proc: unknown swap mode")
	    }

	    # Write line into output file
	    call write (fd, Memc[swapbuf], nchars)
	}
end



procedure i2b_procr (im, imname, ncols, nlines, fd, ftype, swap)

pointer	im				# image descriptor
int	ncols, nlines			# image dimensions
char	imname[ARB]			# image name (error report only)
int	fd				# file descriptor
int	ftype				# input file data type
int	swap				# swap mode

int	line
int	nbytes, nchars
pointer	linebuf, outbuf, swapbuf
pointer	sp

pointer	imgl2r()

include <szpixtype.inc>

begin
#call eprintf ("im=%d, imname=(%s), nc=%d, nl=%d, fd=%d, ft=%d, swap=%d\n")
#call pargi (im)
#call pargstr (imname)
#call pargi (ncols)
#call pargi (nlines)
#call pargi (fd)
#call pargi (ftype)
#call pargi (swap)

	# Determine the number of characters to write to the output
	# file, and the number of bytes to swap (if necessary).
	switch (ftype) {
	case OUTPUT_UBYTE:
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	case OUTPUT_SHORT, OUTPUT_USHORT:
	    nchars = ncols  * pix_size[TY_SHORT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_INT:
	    nchars = ncols  * pix_size[TY_INT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_LONG:
	    nchars = ncols  * pix_size[TY_LONG]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_REAL:
	    nchars = ncols  * pix_size[TY_REAL]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_DOUBLE:
	    nchars = ncols  * pix_size[TY_DOUBLE]
	    nbytes = nchars * SZB_CHAR
	default:
	    call error ("i2b_proc: Unknown output type")
	}

#call eprintf ("nc=%d, nb=%d\n")
#call pargi (nchars)
#call pargi (nbytes)

	# Allocate output and swap buffer. The swap buffer is only
	# allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (outbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)

	# Loop over all image lines
	do line = 1, nlines {

	    # Get image line buffer pointer
	    linebuf = imgl2r (im, line)

	    # Convert to the appropiate data type
	    switch (ftype) {
	    case OUTPUT_UBYTE:
		call achtrb (Memr[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_SHORT, OUTPUT_USHORT:
		call achtrs (Memr[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_INT:
		call achtri (Memr[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_LONG:
		call achtrl (Memr[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_REAL:
		call achtrr (Memr[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_DOUBLE:
		call achtrd (Memr[linebuf], Memc[outbuf], ncols)
	    default:
		call error ("i2b_proc: Unknown output type")
	    }

	    # Swap bytes, if necessary. The swap buffer pointer will
	    # point to the line buffer if no swapping was selected.
	    switch (swap) {
	    case SWAP_NONE:
		swapbuf = outbuf
	    case SWAP_2:
		call bswap2 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    case SWAP_4:
		call bswap4 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    default:
		call error (0, "i2b_proc: unknown swap mode")
	    }

	    # Write line into output file
	    call write (fd, Memc[swapbuf], nchars)
	}
end



procedure i2b_procd (im, imname, ncols, nlines, fd, ftype, swap)

pointer	im				# image descriptor
int	ncols, nlines			# image dimensions
char	imname[ARB]			# image name (error report only)
int	fd				# file descriptor
int	ftype				# input file data type
int	swap				# swap mode

int	line
int	nbytes, nchars
pointer	linebuf, outbuf, swapbuf
pointer	sp

pointer	imgl2d()

include <szpixtype.inc>

begin
#call eprintf ("im=%d, imname=(%s), nc=%d, nl=%d, fd=%d, ft=%d, swap=%d\n")
#call pargi (im)
#call pargstr (imname)
#call pargi (ncols)
#call pargi (nlines)
#call pargi (fd)
#call pargi (ftype)
#call pargi (swap)

	# Determine the number of characters to write to the output
	# file, and the number of bytes to swap (if necessary).
	switch (ftype) {
	case OUTPUT_UBYTE:
	    nchars = ncols / SZB_CHAR
	    nbytes = ncols
	case OUTPUT_SHORT, OUTPUT_USHORT:
	    nchars = ncols  * pix_size[TY_SHORT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_INT:
	    nchars = ncols  * pix_size[TY_INT]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_LONG:
	    nchars = ncols  * pix_size[TY_LONG]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_REAL:
	    nchars = ncols  * pix_size[TY_REAL]
	    nbytes = nchars * SZB_CHAR
	case OUTPUT_DOUBLE:
	    nchars = ncols  * pix_size[TY_DOUBLE]
	    nbytes = nchars * SZB_CHAR
	default:
	    call error ("i2b_proc: Unknown output type")
	}

#call eprintf ("nc=%d, nb=%d\n")
#call pargi (nchars)
#call pargi (nbytes)

	# Allocate output and swap buffer. The swap buffer is only
	# allocated if byte swapping is necessary.
	call smark (sp)
	call salloc (outbuf, nchars, TY_CHAR)
	if (swap != SWAP_NONE)
	    call salloc (swapbuf, nchars, TY_CHAR)

	# Loop over all image lines
	do line = 1, nlines {

	    # Get image line buffer pointer
	    linebuf = imgl2d (im, line)

	    # Convert to the appropiate data type
	    switch (ftype) {
	    case OUTPUT_UBYTE:
		call achtdb (Memd[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_SHORT, OUTPUT_USHORT:
		call achtds (Memd[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_INT:
		call achtdi (Memd[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_LONG:
		call achtdl (Memd[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_REAL:
		call achtdr (Memd[linebuf], Memc[outbuf], ncols)
	    case OUTPUT_DOUBLE:
		call achtdd (Memd[linebuf], Memc[outbuf], ncols)
	    default:
		call error ("i2b_proc: Unknown output type")
	    }

	    # Swap bytes, if necessary. The swap buffer pointer will
	    # point to the line buffer if no swapping was selected.
	    switch (swap) {
	    case SWAP_NONE:
		swapbuf = outbuf
	    case SWAP_2:
		call bswap2 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    case SWAP_4:
		call bswap4 (Memc[outbuf], 1, Memc[swapbuf], 1, nbytes)
	    default:
		call error (0, "i2b_proc: unknown swap mode")
	    }

	    # Write line into output file
	    call write (fd, Memc[swapbuf], nchars)
	}
end


