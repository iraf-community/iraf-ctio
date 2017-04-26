include	"idsmtn.h"
include	"spcombine.h"


# EXP_SCALE - Multiply the rebinned spectra by the the ratio between the
# exposure time of the first spectrum and its exposure time

procedure exp_scale (spectra, nspec)

pointer	spectra[ARB]		# spectra structures
pointer	nspec			# number of spectra

int	i
real	exp1, exp2
pointer	ptr

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("exp_scale: spectra=<%d> nspec=<%d>\n")
		call pargi (spectra)
		call pargi (nspec)
	}

	# Get exposure time for first spectrum
	exp1 = ITM (IN_IDS (spectra[1]))

	# Loop from the second spectrum
	do i = 2, nspec {

	    # Get pointer to next spectrum
	    ptr = spectra[i]

	    # Get exposure time for next spectrum
	    exp2 = ITM (IN_IDS (ptr))

	    # Multiply the spectrum by the exposure time ratio
	    # only if they are different
	    if (exp1 != exp2)
		call amulkr (Memr[IN_PIX (ptr)],
			     exp1 / exp2,
			     Memr[IN_PIX (ptr)],
			     IN_NPIX (ptr))

	    if (clgetb ("debug")) {
		call eprintf ("exp_scale; ptr=<%d> exp1=<%g> exp2=<%g> npix=<%d> pix=<%d>\n")
		    call pargi (ptr)
		    call pargr (exp1)
		    call pargr (exp2)
		    call pargi (IN_NPIX (ptr))
		     call pargi (IN_PIX (ptr))
	    }
	}
end
