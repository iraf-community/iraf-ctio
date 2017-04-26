include	<imhdr.h>
include	<mach.h>
include	"idsmtn.h"
include	"spcombine.h"


# SET_DEFAULTS - Set default values for the starting wavelength, ending
# wavelength, wavelength increment and spectrum length for the output
# spectrum if they have indefined values. These values are calculated
# from the spectra images data.

procedure set_defaults (spectra, nspec, w0, w1, wpc, npix)

pointer	spectra[ARB]		# spectra structures
int	nspec			# number of spectra
real	w0, w1			# starting and ending wavelength
real	wpc			# wavelength increment
int	npix			# spectrum length

int	i
real	aux
pointer	ptr

bool	clgetb()

begin
	# Starting wavelength set to the minimum value of w0 for all images
	if (IS_INDEFR (w0)) {
	    w0 = W0 (IN_IDS (spectra[1]))
	    do i = 2, nspec {
		if (WPC (IN_IDS (spectra[i])) > 0)
		    w0 = min (w0, W0 (IN_IDS (spectra[i])))
		else
		    w0 = max (w0, W0 (IN_IDS (spectra[i])))
	    }
	}

	# Ending wavelength set to the minimum value of
	# (w0 + npix * wpc) of all the spectra images
	if (IS_INDEFR (w1)) {
	    ptr = spectra[1]
	    w1 = W0 (IN_IDS (ptr)) + (IM_LEN (IN_IM (ptr), 1) - 1) *
		 WPC (IN_IDS (ptr))
	    do i = 2, nspec {
		ptr = spectra[i]
		aux = W0 (IN_IDS (ptr)) + (IM_LEN (IN_IM (ptr), 1) - 1) *
		      WPC (IN_IDS (ptr))
		if (WPC (IN_IDS (spectra[i])) > 0)
		    w1 = max (w1, aux)
		else
		    w1 = min (w1, aux)
	    }
	}

	# Wavelength increment set to the minimum value of
	# wpc of all the spectra images
	if (IS_INDEFR (wpc)) {
	    wpc = WPC (IN_IDS (spectra[1]))
	    do i = 2, nspec {
		aux = WPC (IN_IDS (spectra[i]))
		if (abs (aux) < abs (wpc))
		    wpc = aux
	    }
	}

	# Spectrum length is calculated from the previuos
	# quantities
	if (IS_INDEFI (npix))
	    npix = int ((w1 - w0) / wpc + 0.5) + 1

	if (clgetb ("debug")) {
	    call eprintf ("set_defaults: w0=<%g> w1=<%g> wpc=<%g> npix=<%d>\n")
		call pargr (w0)
		call pargr (w1)
		call pargr (wpc)
		call pargi (npix)
	}
end
