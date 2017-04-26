include	<error.h>


# T_LAMBDA - Compute and print the pixel value and corresponding wavelength
# for all the pixels in a list of one dimensional wavelength calibrated
# images.

procedure t_lambda()

int	list			# list of input images
char	w0key[SZ_LINE]		# starting wavelength keyword
char	wpckey[SZ_LINE]		# wavelength increment keyword
bool	convert			# convert wavelengths into angstroms ?

bool	number			# print column number
char	name[SZ_FNAME]		# image name
int	npix			# spectrum length
int	i
real	w0, wpc			# wavelength parameters
real	wave			# pixel wavelength
real	value			# pixel value
pointer	bufptr			# pointer to pixels
pointer	im			# image descriptor

bool	clgetb()
int	clpopnu(), clgfil()
int	imgeti()
real	imgetr()
pointer	immap(), imgl1r()

begin
	# Open input list of images
	list = clpopnu ("input")
	call clgstr ("start", w0key, SZ_LINE)
	call clgstr ("delta", wpckey, SZ_LINE)
	number  = clgetb ("number")
	convert = clgetb ("convert")

	# Loop over images
	while (clgfil (list, name, SZ_FNAME) != EOF) {
	    
	    # Try to open the image
	    iferr (im = immap (name, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get the wavelength parameters from
	    # the header
	    iferr {
		w0 = imgetr (im, w0key)
		wpc = imgetr (im, wpckey)
		npix = imgeti (im, "i_naxis1")
	    } then {
		call erract (EA_WARN)
		next
	    }

	    # Convert wavelength parameters from meters to Angstrom if
	    # they are too small, and if the convert parameter is set.
	    if (w0 < 1.0 && convert) {
		w0 = w0 * 1E+10
		wpc = wpc * 1E+10
	    }

	    # Get line pointer from one dimensional
	    # spectrum
	    bufptr = imgl1r (im)

	    # Print image name
	    call printf ("image = %s\n\n")
		call pargstr (name)

	    # Loop over pixels
	    do i = 1, npix {

		# Evaluate wavelength and get pixel
		# value
		wave = w0 + wpc * (i - 1)
		value = Memr[bufptr + i - 1]

		# Write both values to the standard output
		if (number) {
		call printf ("%g %g %d\n")
		    call pargr (wave)
		    call pargr (value)
		    call pargi (i)
		} else {
		    call printf ("%g %g\n")
		        call pargr (wave)
		        call pargr (value)
		}
	    }

	    # Flush standard output before
	    # opening next image
	    call flush (STDOUT)

	    # Close image
	    call imunmap (im)
	}

	# Close input list
	call clpcls (list)
end
