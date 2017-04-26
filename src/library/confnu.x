# Speed of light
define	VLIGHT		2.997925e18		# cm/seg


# CONFNU -- Convert and spectrum to FNU from FLAMBDA, in place.

procedure confnu (pix, w0, wpc, npts)

real	pix[ARB]		# spectrum pixels
real	w0			# starting wavelength
real	wpc			# wavelength increment
int	npts			# spectrum length

int	i
real	w

begin
	# If the wavelength parameter are not
	# defined, just return.
	if (IS_INDEFR (w0) || IS_INDEFR (wpc))
	    return

	# Convert all pixels
	do i = 1, npts {
	    w = w0 + (i-1) * wpc
	    pix[i] = pix[i] * w**2 / VLIGHT
	}
end
