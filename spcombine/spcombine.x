include	<mach.h>
include	<pkg/gtools.h>
include	"spcombine.h"


# COMBINE_SPECTRA - Combine a list of input spectra.

procedure combine_spectra (insp, outsp, nspec, mode, interactive)

pointer	insp[ARB]		# input spectra structures
pointer	outsp			# output spectrum structure
int	nspec			# number of spectra
int	mode			# interpolation mode
bool	interactive		# combine interactively ?

int	i
int	cmd			# user command from editor
pointer	tempin, tempout		# temporary spectra
pointer	gp, gt			# graphics descriptors
pointer	sp

bool	clgetb()
pointer	gopen(), gt_init()

begin
	if (clgetb ("debug")) {
	    call eprintf ("combine_spectra insp=<%d> outsp=<%d> nspec=<%d> inter=<%b>\n") 
		call pargi (insp)
		call pargi (outsp)
		call pargi (nspec)
		call pargb (interactive)
	}

	# Initialize interactive mode
	if (interactive) {

	    # Allocate memory for temporary input and
	    # output spectra
	    call smark (sp)
	    call salloc (tempin, LEN_IN, TY_STRUCT)
	    call salloc (tempout, LEN_OUT, TY_STRUCT)
	    call init_inspec (tempin)
	    call init_outspec (tempout)

	    # Open graphics output
	    gp = gopen ("stdgraph", NEW_FILE, STDGRAPH)
	    gt = gt_init ()
	    call gt_sets (gt, GTTYPE, "line")
	    call gt_sets (gt, GTXLABEL, "Lambda")
	    call gt_sets (gt, GTXUNITS, "Angstroms")
	}

	# Allocate memory in the heap for the output spectrum
	# and the spectrum of weigths, since these spectra may
	# change its length afterwards
	call malloc (OUT_PIX (outsp), OUT_NPIX (outsp), TY_REAL)
	call malloc (OUT_WTPIX (outsp), OUT_NPIX (outsp), TY_REAL)

	# Loop over input spectra until the last one
	# is reached.
	i = 1
	cmd = COMB_NEXT
	while (i <= nspec) {

	    if (clgetb ("debug")) {
		call eprintf ("next <%d>\n")
		    call pargi (i)
	    }

	    # Combine next spectrum
	    if (interactive) {

	        # Initialize for the first input spectrum
	        if (i == 1) {
		    call copy_outspec (outsp, tempout)
	            call amovkr (BAD_PIX, Memr[OUT_PIX (tempout)],
			         OUT_NPIX (tempout))
	            call amovkr (0.0, Memr[OUT_WTPIX (tempout)],
			         OUT_NPIX (tempout))
	        }

		# Copy current spectrum to a temporary one
		# for editing
		call copy_inspec (insp[i], tempin)

		# Check if it necessary to edit next spectrum
		if (cmd != COMB_BLIND)
		    call edit_spectrum (gp, gt, tempin, tempout, i, nspec,
					mode, cmd)

		# Combine according to last command received
		# from the edit procedure. The default action
		# is to edit again the same spectrum.
		if (cmd == COMB_NEXT || cmd == COMB_BLIND) {
		    call combine_spectrum (tempin, tempout)
		    i = i + 1
		} else if (cmd == COMB_SKIP)
		    i = i + 1
		else if (cmd == COMB_FIRST)
		    i = 1

	    } else {

	        # Initialize for the first input spectrum
	        if (i == 1) {
		    call copy_outspec (outsp, outsp)
	            call amovkr (BAD_PIX, Memr[OUT_PIX (outsp)],
			         OUT_NPIX (outsp))
	            call amovkr (0.0, Memr[OUT_WTPIX (outsp)],
			         OUT_NPIX (outsp))
	        }

		# Combine spctrum and increment counter
	        call combine_spectrum (insp[i], outsp)
		i = i + 1
	    }
	} 

	# End of interactive mode
	if (interactive) {
	    call copy_outspec (tempout, outsp)

	    call gt_sets (gt, GTTITLE, "Combined image")

	    call plot_spectrum (gp, gt, Memr[OUT_PIX (outsp)],
				OUT_NPIX (outsp), OUT_W0 (outsp),
				OUT_W1 (outsp))
	    call gclose (gp)
	    call gt_free (gt)

	    call mfree (IN_PIX (tempin), TY_REAL)
	    call mfree (OUT_PIX (tempout), TY_REAL)

	    call sfree (sp)
	}
end


# COMBINE_SPECTRUM -- Combine overlapping pixels of input spectrum
# with the partially combined spectrum.

procedure combine_spectrum (insp, outsp)

pointer	insp		# input spectrum structure
pointer	outsp		# output spectrum structure

int	i, i1, i2
pointer	pixin, pixsum, pixwt

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("combine_spectrum insp=<%d> outsp=<%d>\n")
		call pargi (insp)
		call pargi (outsp)
	}

	# Get index in output spectrum and truncate
	# them if they are out of bounds
	i1 = max (OUT_INDEX (outsp, IN_W0 (insp)), 1)
	i2 = min (i1 + IN_NPIX (insp) - 1, OUT_NPIX (outsp))

	if (clgetb ("debug")) {
	    call eprintf ("combine_spectrum: i1=<%d> i2=<%d>\n")
		call pargi (i1)
		call pargi (i2)
	}

	# Loop over input pixels
	do i = i1, i2 {

	    # Compute pointers
	    pixin = IN_PIX (insp) + i - i1
	    pixsum = OUT_PIX (outsp) + i - 1
	    pixwt = OUT_WTPIX (outsp) + i - 1

	    # Combine input spectrum with sum
	    if (Memr[pixin] != BAD_PIX && Memr[pixsum] != BAD_PIX) {
		Memr[pixsum] = (Memr[pixin] * IN_WT (insp) +
				Memr[pixsum] * Memr[pixwt]) /
				(IN_WT (insp) + Memr[pixwt])
		Memr[pixwt] = IN_WT (insp) + Memr[pixwt]
	    } else if (Memr[pixin] != BAD_PIX) {
		Memr[pixsum] = Memr[pixin]
		Memr[pixwt] = IN_WT (insp)
	    }
	}
end
