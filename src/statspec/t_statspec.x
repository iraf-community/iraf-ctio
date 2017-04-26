include	<error.h>


# T_STATSPEC - Compute error spectra from object and sky spectra.

procedure t_statspec ()

char	outname[SZ_FNAME]	# output name
char	outroot[SZ_FNAME]	# output name
char	objname[SZ_FNAME]	# object name
char	skyname[SZ_FNAME]	# sky name
int	objlist, skylist	# input lists
int	npix			# spectum length
int	i
real	ron			# readout noise
real	preflash
real	gain
real	nstar, nsky
real	temp
pointer	objim, skyim, outim		# image descriptors
pointer	objbuff, skybuff, outbuff	# buffer pointers

bool	streq()
int	clpopnu(), clgfil()
int	imgeti()
real	clgetr()
pointer	immap(), imgl1r(), impl1r()

begin
	# Get input lists
	objlist = clpopnu ("object_spectra")
	skylist = clpopnu ("sky_spectra")

	# Get output file name and check it
	call clgstr ("error_spectra", outroot, SZ_FNAME)
	if (streq (outroot, ""))
	    call strcpy ("out", outroot, SZ_FNAME)

	# Get parameters
	ron = clgetr ("ron")
	preflash = clgetr ("preflash")
	gain = clgetr ("gain")
	nstar = clgetr ("nstar")
	nsky = clgetr ("nsky")

	# Loop over list
	while (clgfil (objlist, objname, SZ_FNAME) != EOF) {

	    # Test sky list length
	    if (clgfil (skylist, skyname, SZ_FNAME) == EOF) {
		call eprintf ("Error: sky list shorter than object list\n")
		break
	    }

	    # Open input images
	    iferr (objim = immap (objname, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }
	    iferr (skyim = immap (skyname, READ_ONLY, 0)) {
		call imunmap (objim)
		call erract (EA_WARN)
		next
	    }

	    # Test spectrum dimensions
	    if (imgeti (objim, "i_naxis") != 1 ||
		imgeti (skyim, "i_naxis") != 1) {
		call imunmap (objim)
		call imunmap (skyim)
		call eprintf (
		    "Object or sky spectrum not one-dimensional -> %s\n")
		    call pargstr (objname)
		next
	    }

	    # Test spectrum lengths
	    if (imgeti (objim, "i_naxis1") != imgeti (skyim, "i_naxis1")) {
		call imunmap (objim)
		call imunmap (skyim)
		call eprintf (
		    "Object spectrum length != sky spectrum length -> %s\n")
		    call pargstr (objname)
		next
	    }

	    # Build output name
	    call sprintf (outname, SZ_FNAME, "%s%s")
		call pargstr (outroot)
		call pargstr (objname)

	    # Open output image
	    iferr (outim = immap (outname, NEW_COPY, objim)) {
		call erract (EA_WARN)
		call imunmap (objim)
		call imunmap (skyim)
		next
	    }

	    # Get image data pointers
	    objbuff = imgl1r (objim)
	    skybuff = imgl1r (skyim)
	    outbuff = impl1r (outim)

	    # Get output spectum length
	    npix = imgeti (objim, "i_naxis1")

	    # Compute output spectrum
	    do i = 1, npix {
		temp = (Memr[skybuff+i-1) * gain / nstar + ron * ron +
			preflash) * nsky * nstar / (nsky - 1) +
			Memr[objbuff+i-1] * gain
		if (Memr[objbuff+i-1] == 0) {
		    if (i == 1)
			Memr[outbuff+i-1] = 0.01
		    else
			Memr[outbuff+i-1] = Memr[outbuff+i-2]
		} else
		    Memr[outbuff+i-1] = sqrt (temp) / Memr[objbuff+i-1] / gain
	    }

	    # Close images
	    call imunmap (objim)
	    call imunmap (skyim)
	    call imunmap (outim)
	}
	
	# Close lists
	call clpcls (objlist)
	call clpcls (skylist)
end
