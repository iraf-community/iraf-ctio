include	"idsmtn.h"
include	"spcombine.h"


# SORT_HDRS - Sort the spectra in the structures by starting wavelength,
# according to the sort mode.

procedure sort_hdrs (spectra, nspec, sort)

pointer	spectra[ARB]		# spectra structures
int	nspec			# number of spectra
int	sort			# sort mode

int	i, j
pointer	ptr

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("sort_hdrs: nspec=<%d> sort=<%d>\n")
		call pargi (nspec)
		call pargi (sort)
	}

	# Decide wether to sort the output list in increasing or
	# decreasing order, or to leave it untouched.
	if (sort == SORT_INC) {
	    do i = 1, nspec - 1
	        do j = i, nspec
		    if (W0 (IN_IDS (spectra[i])) > W0 (IN_IDS (spectra[j]))) {
			ptr = spectra[i]
			spectra[i] = spectra[j]
			spectra[j] = ptr
		    }
	} else if (sort == SORT_DEC) {
	    do i = 1, nspec - 1
	        do j = i, nspec
		    if (W0 (IN_IDS (spectra[i])) < W0 (IN_IDS (spectra[j]))) {
			ptr = spectra[i]
			spectra[i] = spectra[j]
			spectra[j] = ptr
		    }
	}
end
