include	<error.h>
include	<math.h>

# Initial buffer size for text files
define	INIT_SIZE	512

# Transformation types
define	TRANS_TYPES		"|real|complex|"
define	TYPE_REAL		1
define	TYPE_COMPLEX		2

# Output formats
define	OUTPUT_FORMATS		"|plain|modulus|power|"
define	FORMAT_PLAIN		1
define	FORMAT_MODULUS		2
define	FORMAT_POWER		3

# Size of a FITS image keyword name (characters)
define	SZ_KEYWORD		8

# Image keyword name used to store the value of the starting value keyword,
# from the input image header, during a direct transformation. This value
# is used afterwards, during the inverse transformation, in order to restore
# the original starting value.
define	KEY_OLDSTART		"FFT1DVAL"


# T_FFT1D -- One-dimensional Fast Fourier Transform of a list of images
# and/or text files.

procedure t_fft1d ()

bool	inverse			# inverse transformation ?
bool	flip			# flip negative/positive parts ?
bool	angular			# show angular frecuencies ?
char	input[SZ_FNAME]		# input file name
char	output[SZ_FNAME]	# output file name
char	valkey[SZ_KEYWORD]	# starting value keyword name
char	intkey[SZ_KEYWORD]	# interval keyword name
char	dummy[2]
int	type			# transformation type
int	format			# output format
int	inlist, outlist		# input and output lists
int	fdin, fdout		# file descriptors
real	interval		# sampling interval
pointer	imin, imout		# image descriptors

bool	clgetb()
int	clgwrd()
int	clpopni(), clpopnu(), clgfil()
int	open()
int	imgeti()
real	clgetr()
pointer	immap()

begin
	# Get parameters
	inlist   = clpopni ("input")
	outlist  = clpopnu ("output")
	type     = clgwrd  ("type", dummy, 2, TRANS_TYPES)
	inverse  = clgetb  ("inverse")
	format   = clgwrd  ("format", dummy, 2, OUTPUT_FORMATS)
	flip     = clgetb  ("flip")
	interval = clgetr  ("interval")
	call clgstr ("valkey", valkey, SZ_KEYWORD)
	call clgstr ("intkey", intkey, SZ_KEYWORD)
	angular  = clgetb  ("angular")

	# Loop over input list
	while (clgfil (inlist, input, SZ_FNAME) != EOF) {

	    # Get output file/image name
	    if (clgfil (outlist, output, SZ_FNAME) == EOF)
		call error (0, "Output list shorter than input list")

	    # Try to open input file as as image. If the operation is
	    # not successfull try to open it as a text file.
	    ifnoerr (imin = immap (input, READ_ONLY, 0)) {

		# Check image dimension
		if (imgeti (imin, "i_naxis")  > 1 &&
		    imgeti (imin, "i_naxis2") > 1) {
		    call eprintf ("Image (%s) not one dimensional\n")
			call pargstr (input)
		    call imunmap (imin)
		    next
		}

		# Open output image
		iferr (imout = immap (output, NEW_COPY, imin)) {
		    call erract (EA_WARN)
		    call imunmap (imin)
		    next
		}

		# Convert image
		call fft1_image (imin, imout, type, format, inverse, flip,
				 valkey, intkey, angular)

		# Close images
		call imunmap (imin)
		call imunmap (imout)

	    } else ifnoerr (fdin = open (input, READ_ONLY, TEXT_FILE)) {

		# Open output file
		iferr (fdout = open (output, NEW_FILE, TEXT_FILE)) {
		    call erract (EA_WARN)
		    call close (fdin)
		    next
		}

		# Convert output file
		call fft1_text (fdin, fdout, type, format, inverse, flip,
				interval, angular)

		# Close files
		call close (fdin)
		call close (fdout)

	    } else {
		call erract (EA_WARN)
		next
	    }
	}

	# Close lists
	call clpcls (inlist)
	call clpcls (outlist)
end


# FFT1_TEXT -- One-dimensional FFT of a text file

procedure fft1_text (fdin, fdout, type, format, inverse, flip,
		     interval, angular)

int	fdin			# input file descriptor
int	fdout			# output file descriptor
int	type			# transformation type
int	format			# output format
bool	inverse			# inverse transformation ?
bool	flip			# flip negative/positive parts ?
real	interval		# sampling interval
bool	angular			# show angular frecuencies ?

int	n, npts
int	nstart1, nend1
int	nstart2, nend2
real	xr, xi
pointer	fft

int	fscan(), nscan()
int	fft1_get(), fft1_size()

begin
	# Initialize FFT.
	call fft1_init (fft, INIT_SIZE, (type == TYPE_REAL), inverse, flip)

	# Read data from file
	while (fscan (fdin) != EOF) {

	    # Read data point
	    call gargr (xr)
	    call gargr (xi)
	    if (nscan () < 1)
		next
	    if (nscan () < 2)
		xi = 0.0
		    
	    # Put data into buffers
	    call fft1_put (fft, xr, xi)
	}
	
	# Take the transformation of the data in the buffer
	call fft1_fft (fft)

	# Get actual number of points in the transformation
	npts = fft1_size (fft)

	# Set up loop limits. There are two loops when the frequency
	# values are written, since there is a discontinuity at zero
	# when the output is not flipped.
	if (IS_INDEFR (interval)) {
	    nstart1 = 0
	    nend1   = npts - 1
	} else {
	    if (flip) {
		nstart1 = 1 - npts / 2
		nend1   = -1
		nstart2 = 0
		nend2   = npts / 2
	    } else {
		nstart1 = 0
		nend1   = npts / 2
		nstart2 = 1 - npts / 2
		nend2   = -1
	    }
	}

	# Write the buffer to the output file with the appropiate format
	switch (format) {
	case FORMAT_PLAIN:
	    if (IS_INDEFR (interval)) {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g\n")
			    call pargr (xr)
			    call pargr (xi)
		    } else
			call error (0, "fft_text: End of data before expected")
		}
	    } else {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g %g\n")
			    if (angular)
				call pargr (n * TWOPI / (npts * interval))
			    else
				call pargr (n / (npts * interval))
			    call pargr (xr)
			    call pargr (xi)
		    } else
			call error (0, "fft1_text: End of data before expected")
		}
		do n = nstart2, nend2 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g %g\n")
			    if (angular)
				call pargr (n * TWOPI / (npts * interval))
			    else
				call pargr (n / (npts * interval))
			    call pargr (xr)
			    call pargr (xi)
		    } else
			call error (0, "fft1_text: End of data before expected")
		}
	    }

	case FORMAT_MODULUS:
	    if (IS_INDEFR (interval)) {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g\n")
			    call pargr (sqrt (xr * xr + xi * xi))
		    } else
			call error (0, "fft_text: End of data before expected")
		}
	    } else {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g\n")
			if (angular)
			    call pargr (n * TWOPI / (npts * interval))
			else
			    call pargr (n / (npts * interval))
			call pargr (sqrt (xr * xr + xi * xi))
		    } else
			call error (0, "fft_text: End of data before expected")
		}
		do n = nstart2, nend2 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g\n")
			if (angular)
			    call pargr (n * TWOPI / (npts * interval))
			else
			    call pargr (n / (npts * interval))
			call pargr (sqrt (xr * xr + xi * xi))
		    } else
			call error (0, "fft_text: End of data before expected")
		}
	    }

	case FORMAT_POWER:
	    if (IS_INDEFR (interval)) {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g\n")
			    call pargr (xr * xr + xi * xi)
		    } else
			call error (0, "fft_text: End of data before expected")
		}
	    } else {
		do n = nstart1, nend1 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g\n")
			if (angular)
			    call pargr (n * TWOPI / (npts * interval))
			else
			    call pargr (n / (npts * interval))
			call pargr (xr * xr + xi * xi)
		    } else
			call error (0, "fft_text: End of data before expected")
		}
		do n = nstart2, nend2 {
		    if (fft1_get (fft, xr, xi) != EOF) {
			call fprintf (fdout, "%g %g\n")
			if (angular)
			    call pargr (n * TWOPI / (npts * interval))
			else
			    call pargr (n / (npts * interval))
			call pargr (xr * xr + xi * xi)
		    } else
			call error (0, "fft_text: End of data before expected")
		}
	    }

	default:
	    call error (0, "fft1_text: Unknown output format")
	}

	# Free memory
	call fft1_free (fft)
end


# FFT1_IMAGE -- One-dimensional FFT of an image.

procedure fft1_image (imin, imout, type, format, inverse, flip, 
		      valkey, intkey, angular)

pointer	imin			# input image descriptor
pointer	imout			# output image descriptor
int	type			# transformation type
int	format			# output format
bool	inverse			# inverse transformation ?
bool	flip			# flip negative/positive parts ?
char	valkey[ARB]		# value keyword name
char	intkey[ARB]		# interval keyword name
bool	angular			# show angular frecuencies ?

int	n, npix, npts
int	fft1_get()
real	start, oldstart, interval
real	xr, xi
pointer	fft, bufptr

int	imgeti()
int	fft1_size()
real	imgetr()
pointer	imgl1r(), imgl1x(), impl1r(), impl1x()

begin
	# Initialize FFT
	npix = imgeti (imin, "naxis1")
	call fft1_init (fft, npix, (type == TYPE_REAL), inverse, flip)

	# Put image pixels as complex numbers in the fft buffer.
	# The image is read as complex only if it's a complex image
	# because reading always as complex gave some problems with
	# the data. All other data types are read as real.
	if (imgeti (imin, "i_pixtype") == TY_COMPLEX) {
	    bufptr = imgl1x (imin)
	    do n = 0, npix - 1 {
		xr = real  (Memx[bufptr + n])
		xi = aimag (Memx[bufptr + n])
		call fft1_put (fft, xr, xi)
	    }
	} else {
	    bufptr = imgl1r (imin)
	    do n = 0, npix - 1 {
		xr = Memr[bufptr + n]
		xi = 0.0
		call fft1_put (fft, xr, xi)
	    }
	}

	# Take the transformation
	call fft1_fft (fft)

	# Get actual number of points in the transformation
	npts = fft1_size (fft)

	# Update the output image length. This is necessary because the
	# output image is a "new copy" of the input image, and the number
	# of points in the transformation may not be equal to the number
	# of pixels in the input image.
	call imputi (imout, "i_naxis1", npts)

	# Write the output image line with the appropiate format
	switch (format) {
	case FORMAT_PLAIN:
	    call imputi (imout, "i_pixtype", TY_COMPLEX)
	    bufptr = impl1x (imout)
	    do n = 0, npts - 1 {
		if (fft1_get (fft, xr, xi) != EOF)
		    Memx[bufptr + n] = complex (xr, xi)
		else
		    call error (0, "fft_image: End of data before expected")
	    }

	case FORMAT_MODULUS:
	    call imputi (imout, "i_pixtype", TY_REAL)
	    bufptr = impl1r (imout)
	    do n = 0, npts - 1 {
		if (fft1_get (fft, xr, xi) != EOF)
		    Memr[bufptr + n] = sqrt (xr * xr + xi * xi)
		else
		    call error (0, "fft_image: End of data before expected")
	    }

	case FORMAT_POWER:
	    call imputi (imout, "i_pixtype", TY_REAL)
	    bufptr = impl1r (imout)
	    do n = 0, npts - 1 {
		if (fft1_get (fft, xr, xi) != EOF)
		    Memr[bufptr + n] = xr * xr + xi * xi
		else
		    call error (0, "fft_image: End of data before expected")
	    }

	default:
	    call error (0, "fft1_image: Unknown output format")
	}

	# Get starting value and  pixel interval from the input image header.
	iferr (start = imgetr (imin, valkey))
	    start = INDEFR
	iferr (interval = imgetr (imin, intkey))
	    interval = INDEFR

	# Update the output image header only if both the starting
	# value and the interval are specified in the input image,
	# i.e. if "valkey" and "intkey" are present in the header.
	if (!IS_INDEFR (start) && !IS_INDEFR (interval)) {

	    # Put the starting value in the output image header. The
	    # action is different depending on the transformation
	    # direction, and whether the output is flipped or not.
	    if (inverse) {
		ifnoerr (oldstart = imgetr (imin, KEY_OLDSTART))
		    call imputr (imout, valkey, oldstart) {
		    call imdelf (imout, KEY_OLDSTART)
		}
	    } else {
		if (flip) {
		    if (angular)
		        call imputr (imout, valkey,
				     (1 - npts) * TWOPI / (npts * interval))
		    else
		        call imputr (imout, valkey,
				     (1 - npts) / (npts * interval))
		} else
		    call imputr (imout, valkey, 0.0)
		call imaddr (imout, KEY_OLDSTART, start)
	    }

	    # Put the interval in the output image header
	    if (angular)
		call imputr (imout, intkey, TWOPI / (interval * npts))
	    else
		call imputr (imout, intkey, 1.0 / (interval * npts))
	}

	# Free memory
	call fft1_free (fft)
end
