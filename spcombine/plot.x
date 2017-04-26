# PLOT_SPECTRA - Overplot two spectra

procedure plot_spectra (gp, gt, pix1, pix2, npix1, npix2, x11, x12, x21, x22)

pointer	gp			# graphics descriptor
pointer	gt			# GTOOLS graphics descriptor
real	pix1[ARB],pix2[ARB]	# pixels
int	npix1, npix2		# number of pixels
real	x11, x12		# data x limits for first array
real	x21, x22		# data x limits for second array

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("plot_spectra: gp=<%d> gt=<%d> pix1=<%g> pix2=<%g> npix1=<%d> npix2=<%d> x11=<%g> x12=<%g> x21=<%g> x22=<%g>\n")
		call pargi (gp)
		call pargi (gt)
		call pargr (pix1[1])
		call pargr (pix2[1])
		call pargi (npix1)
		call pargi (npix2)
		call pargr (x11)
		call pargr (x12)
		call pargr (x21)
		call pargr (x22)
	}

	# Set up graphics window
	call gclear (gp)
	call gswind (gp, min (x11, x21), max (x12, x22), INDEFR, INDEFR)
	call gascale (gp, pix2, npix2, 2)
	call grscale (gp, pix1, npix1, 2)
	call gt_swind (gp, gt)
	call gt_labax (gp, gt)

	# Plot first spectrum
	call gt_vplot (gp, gt, pix1, npix1, x11, x12)

	# Plot second spectrum
	call gt_vplot (gp, gt, pix2, npix2, x21, x22)
end


# PLOT_SPECTRUM - Plot a single spectrum

procedure plot_spectrum (gp, gt, pix, npix, x1, x2)

pointer	gp		# graphics descriptor
pointer	gt		# GTOOLS graphics descriptor
real	pix[npix]	# pixels
int	npix		# number of pixels
real	x1, x2		# data x limits

begin
	# Set up graphics window
	call gclear (gp)
	call gswind (gp, x1, x2, INDEFR, INDEFR)
	call gascale (gp, pix, npix, 2)
	call gt_swind (gp, gt)
	call gt_labax (gp, gt)

	# Plot spectrum
	call gt_vplot (gp, gt, pix, npix, x1, x2)
end
