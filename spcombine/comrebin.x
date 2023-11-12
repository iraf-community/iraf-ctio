include	<imhdr.h>
include	<math/iminterp.h>
include	"idsmtn.h"
include	"spcombine.h"


# REBIN_SPECTRA - Rebin all the input spectra adjusting the rebinned
# spectra.

procedure rebin_spectra (inspec, outspec, nspec, mode)

pointer	inspec[ARB]		# input spectra structures
pointer	outspec			# output spectra structures
int	nspec			# number of spectra
int	mode			# interpolation mode

bool	login
int	i
pointer	ptr

bool	clgetb()
pointer	imgl1r()

begin
	if (clgetb ("debug")) {
	    call eprintf ("rebin_spectra: inspec=<%d> outspec=<%d> nspec=<%d> mode=<%d>\n")
	    	call pargi (inspec)
	    	call pargi (outspec)
	    	call pargi (nspec)
	    	call pargi (mode)
	}

	# Loop over input spectra
	do i = 1, nspec {

	    # Pointer to next spectrum
	    ptr = inspec[i]

	    # Get log scale of input spectrum
	    if (DC_FLAG (IN_IDS (ptr)) == 1)
		login = true
	    else
		login = false

	    # Rebin and adjust the spectrum
	    call rebin_adjust (W0 (IN_IDS (ptr)), WPC (IN_IDS (ptr)),
			       IM_LEN (IN_IM (ptr), 1), login,
			       imgl1r (IN_IM (ptr)),
			       OUT_W0 (outspec), OUT_WPC (outspec),
			       OUT_NPIX (outspec), OUT_LOG (outspec),
			       mode,
			       IN_PIX (ptr), IN_W0 (ptr), IN_W1 (ptr),
			       IN_WPC (ptr), IN_NPIX (ptr))
	}
end


# REBIN_ADJUST - Rebin the input spectrum and eliminate the leading
# and trailing blank pixels from it. The adjusted wavelength parameters
# and spectrum length contain the information of the adjusting.

procedure rebin_adjust (w0in, wpcin, npixin, login, pixin,
			w0out, wpcout, npixout, logout, mode,
			pixout, adjw0, adjw1, adjwpc, adjnpix)

real	w0in, wpcin		# input wavelength parameters
int	npixin			# input spectrum length
bool	login			# input log scale ?
pointer	pixin			# input pixels
real	w0out, wpcout		# output wavelength parameters
int	npixout			# output spectrum length
bool	logout			# output log scale ?
int	mode			# interpolation mode
pointer	pixout			# output pixels (rebinned)
real	adjw0, adjw1, adjwpc	# adjusted wavelength parameters
int	adjnpix			# adjusted spectrum length

bool	flag
int	i, i1, i2
pointer	sp
pointer	temp

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("rebin_adjust: w0in=<%g> wpcin=<%g> npixin=<%d> login=<%b> pixin=<%d>\n")
		call pargr (w0in)
		call pargr (wpcin)
		call pargi (npixin)
		call pargb (login)
		call pargi (pixin)
	    call eprintf ("rebin_adjust: w0out=<%g> wpcout=<%g> npixout=<%d> logout=<%b> mode=<%d>\n")
		call pargr (w0out)
		call pargr (wpcout)
		call pargi (npixout)
		call pargb (logout)
		call pargi (mode)
	}

	# Allocate space for rebinned spectrum
	call smark (sp)
	call salloc (temp, npixout, TY_REAL)

	# Rebin spectrum
	call rebin_spectrum (w0in, wpcin, npixin, login, pixin,
			     w0out, wpcout, npixout, logout, temp, mode)

	# Clear flag, indexes and output
	# parameters
	flag = true
	i1 = INDEFI
	i2 = INDEFI
	adjw0 = INDEFR
	adjw1 = INDEFR
	adjwpc = INDEFR
	adjnpix = INDEFI
	pixout = NULL

	# Determine the lower and upper bounds of the
	# rebinned spectrum
	do i = 1, npixout {
	    if (Memr[temp+i-1] != BAD_PIX && flag) {
		i1 = i
		flag = false
	    }
	    if (Memr[temp+i-1] != BAD_PIX && !flag)
		i2 = i
	}

	# Check if there is a defined range
	if (!(IS_INDEFI (i1) || IS_INDEFI (i2))) {

	    # Convert indexes to adjusted starting and ending 
	    # wavelengths, and calculate the adjusted wavelength
	    # increment and spectrum length
	    adjw0 = w0out + (i1 - 1) * wpcout
	    adjw1 = w0out + (i2 - 1) * wpcout
	    adjnpix = i2 - i1 + 1
	    adjwpc = wpcout

	    # Allocate memory for the adjusted spectrum in the heap
	    # because it must be retained  upon return of the procedure
	    # and may change its length afterwards
	    call malloc (pixout, adjnpix, TY_REAL)

	    # Copy the rebinned spectrum into the adjuted
	    # spectrum, skipping the blank pixels region
	    call amovr (Memr[temp+i1-1], Memr[pixout], adjnpix)
	}

	# Free memory
	call sfree (sp)

	if (clgetb ("debug")) {
	    call eprintf ("rebin_adjust: pixout=<%d> adjw0=<%g> adjw1=<%g> adjwpc=<%g> adjnpix=<%d>\n")
		call pargi (pixout)
		call pargr (adjw0)
		call pargr (adjw1)
		call pargr (adjwpc)
		call pargi (adjnpix)
	}
end


# REBIN_SPECTRUM - Rebin the input spectrum

procedure rebin_spectrum (w0in, wpcin, npixin, login, pixin,
			  w0out, wpcout, npixout, logout, pixout,
			  mode)

real	w0in, wpcin		# input wavelength parameters
int	npixin			# input spectrum length
bool	login			# input log scale ?
pointer	pixin			# input pixels
real	w0out, wpcout		# output wavelength parameters
int	npixout			# output spectrum length
bool	logout			# output log scale ?
pointer	pixout			# output pixels (rebinned)
int	mode			# interpolation mode

pointer	invert			# lambda to pixel table
pointer	sp

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("rebin_spectrum: w0in=<%g> wpcin=<%g> npixin=<%d> login=<%b> pixin=<%d>\n")
		call pargr (w0in)
		call pargr (wpcin)
		call pargi (npixin)
		call pargb (login)
		call pargi (pixin)
	    call eprintf ("rebin_spectrum: w0out=<%g> wpcout=<%g> npixout=<%d> logout=<%b> pixout=<%d> mode=<%d>\n")
		call pargr (w0out)
		call pargr (wpcout)
		call pargi (npixout)
		call pargb (logout)
		call pargi (pixout)
		call pargi (mode)
	}

	# Allocate memory for lambda to pixel table and
	# rebinned spectrum
	call smark (sp)
	call salloc (invert, npixout, TY_REAL)

	# Compute pixel position as a function of lambda.
	call lambda_to_pixel2 (w0out, wpcout, w0in, wpcin,
			       login, npixout, logout, Memr[invert])

	# Interpolate
	switch (mode) {
	case RB_LINEAR:
	    call reinterp (Memr[pixin], Memr[pixout], Memr[invert],
	 		   npixout, npixin, II_LINEAR)
	case RB_SPLINE3:
	    call reinterp (Memr[pixin], Memr[pixout], Memr[invert],
			   npixout, npixin, II_SPLINE3)
	case RB_POLY3:
	    call reinterp (Memr[pixin], Memr[pixout], Memr[invert],
			   npixout, npixin, II_POLY3)
	case RB_POLY5:
	    call reinterp (Memr[pixin], Memr[pixout], Memr[invert],
			   npixout, npixin, II_POLY5)
	case RB_SUMS:
	    call resum (Memr[pixin], Memr[pixout], Memr[invert],
	 		npixout, npixin)
	}

	# Free memory
	call sfree (sp)
end
