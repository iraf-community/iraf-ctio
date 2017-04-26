include	<imhdr.h>
include	<error.h>
include	"idsmtn.h"
include "spcombine.h"

# SPCOMBINE -

procedure t_spcombine()

char	output[SZ_FNAME]	# output image name
char	wtimage[SZ_FNAME]	# image name for spectrum weights
char	aux[SZ_FNAME]
bool	exposure		# scale by exposure time ?
bool	fluxcons		# conserve flux ?
bool	interactive		# adjust spectrum interactive ?
int	sort			# sort mode
int	nspec			# mumber of input spectra
int	list			# list of input images
int	wtype			# weigthing type
int	intmode			# interpolation mode
int	i
pointer	sp
pointer	inspec[MAX_NR_SPECTRA]	# input spectra structures
pointer	outspec			# output spectrum structure
pointer	ptr

bool	streq(), clgetb()
int	clgeti(), clgwrd()
int	clpopnu(), clgfil()
real	clgetr()
pointer	immap()

begin
	# Start memory allocation
	call smark (sp)

	# Get positional parameters
	list = clpopnu ("input")
	call clgstr ("output", output, SZ_FNAME)

	if (streq (output, ""))
	    call error (0, "Null output name")

	# Get output spectrum parameters
	call salloc (outspec, LEN_OUT, TY_STRUCT)
	OUT_W0 (outspec) = clgetr ("w0")
	OUT_W1 (outspec) = clgetr ("w1")
	OUT_WPC (outspec) = clgetr ("wpc")
	OUT_NPIX (outspec) = clgeti ("nout")
	OUT_LOG (outspec) = clgetb ("logarithm")

	# Get remaining parameters
	intmode = clgwrd ("interp_mode", aux, SZ_FNAME, INTERP_MODE)
	wtype = clgwrd ("wt_type", aux, SZ_FNAME, WT_TYPE)
	call clgstr ("wt_image", wtimage, SZ_FNAME)
	sort = clgwrd ("sort", aux, SZ_FNAME, SORT_MODE)
	exposure = clgetb ("exposure")
	fluxcons = clgetb ("fluxcons")
	interactive = clgetb ("interactive")

	# Load header information and image descriptors
	# Skip images with no wavelength information and
	# optionally with no exposure time information
	nspec = 0
	ptr = NULL
	while (clgfil (list, aux, SZ_FNAME) != EOF) {

	    if (clgetb ("debug")) {
		call eprintf ("%s\n")
		    call pargstr (aux)
	    }

	    # Check maximum number of input spectra
	    if (nspec == MAX_NR_SPECTRA) {
	        call eprintf ("Too many spectra in input list (truncated)\n")
		break
	    }

	    # Allocate memory for input image structure
	    if (ptr == NULL)
	        call salloc (ptr, LEN_IN, TY_STRUCT)

	    # Open the input image or issue warning
	    # message if it cannot be opened
	    iferr (IN_IM(ptr) = immap (aux, READ_ONLY, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Allocate memory for header and load it
	    call salloc (IN_IDS (ptr), LEN_IDS, TY_STRUCT)
	    call salloc (POINT (IN_IDS (ptr)), MAX_NCOEFF, TY_REAL)
	    call load_ids_hdr (IN_IDS (ptr), IN_IM (ptr))

	    # Count image headers only if the wavelength
	    # and exposure time information are there
	    if (IS_INDEFR (W0 (IN_IDS (ptr)))) {
		call eprintf ("Warning: No starting wavelength in %s\n")
		    call pargstr (aux)
		next
	    } else if (IS_INDEFR (WPC (IN_IDS (ptr)))) {
		call eprintf ("Warning: No wavelength increment in %s\n")
		    call pargstr (aux)
		next
	    } else if (IS_INDEFR (ITM (IN_IDS (ptr))) && exposure) {
		call eprintf ("Warning: No exposure time in %s\n")
		    call pargstr (aux)
		next
	    } else {
		IN_W0 (ptr) = INDEFR
		IN_W1 (ptr) = INDEFR
		IN_WPC (ptr) = INDEFR
		IN_NPIX (ptr) = INDEFI
		IN_PIX (ptr) = NULL
	        nspec = nspec + 1
	        inspec[nspec] = ptr
		ptr = NULL
	    }
	}

	if (clgetb ("debug")) 
	    call debug_in (inspec, nspec)

	# Close image list
	call clpcls (list)

	# Get weighting parameters
	if (wtype == WT_USER) {
	    do i = 1, nspec {
		call printf ("For [%s]:")
		    call pargstr ("")
		call flush (STDOUT)
		IN_WT (inspec[i]) = clgetr ("weight")
	    }
	} else if (wtype == WT_EXPO) {
	    do i = 1, nspec
		IN_WT (inspec[i]) = ITM (IN_IDS (inspec[i]))
	} else {
	    do i = 1, nspec
	        IN_WT (inspec[i]) = 1.0
	}


	if (clgetb ("debug"))
	    call debug_in (inspec, nspec)

	# Check if there are images to combine
	if (nspec > 1) {

	    # Sort the headers list according
	    # to the mode selected
	    call sort_hdrs (inspec, nspec, sort)

	    if (clgetb ("debug"))
	        call debug_in (inspec, nspec)

	    # Set default values for starting wavelength, ending
	    # wavelength, wavelength increment and specgrum length
	    # for output spectrum
	    call set_defaults (inspec, nspec, OUT_W0 (outspec), 
			       OUT_W1 (outspec), OUT_WPC (outspec),
			       OUT_NPIX (outspec))

	    if (clgetb ("debug"))
		call debug_out (outspec)

	    # Rebin input spectra
	    call rebin_spectra (inspec, outspec, nspec, intmode)
	    
	    if (clgetb ("debug"))
		call debug_in (inspec, nspec)

	    # Scale to exposure time
	    if (exposure)
		call exp_scale (inspec, nspec)

	    # Combine spectra
	    call combine_spectra (inspec, outspec, nspec, intmode, interactive)

	    if (clgetb ("debug"))
		call debug_out (outspec)

	    # Write output and weight spectra
	    call write_spectra (inspec, outspec, output, wtimage)

	    # Free memory and image buffers
	    do i = 1, nspec {
		call imunmap (IN_IM (inspec[i]))
		call mfree (IN_PIX (inspec[i]), TY_REAL)
	    }
	    call mfree (OUT_PIX (outspec), TY_REAL)
	    call mfree (OUT_WTPIX (outspec), TY_REAL)

	} else
	    call eprintf ("Not enough images to combine\n")

	# Free stack memory
	call sfree (sp)
end


# WRITE_SPECTRA -  Write the output and weigths spectra into two
# images on disk

procedure write_spectra (inspec, outspec, outname, wtname)

pointer	inspec[ARB]		# input spectra structures
pointer	outspec			# output spectrum structure
char	outname[SZ_FNAME]	# output spectrum name
char	wtname[SZ_FNAME]	# weigth spectrum name

pointer	im, ids

bool	strne()
pointer	immap(), impl1r()

begin
	# Write output image using the first input image
	# as a reference
	im = immap (outname, NEW_COPY, IN_IM (inspec[1]))
	IM_NDIM (im) = 1
	IM_LEN (im, 1) = IN_NPIX (outspec)
	IM_PIXTYPE (im) = TY_REAL
	call strcpy ("Combined image", IM_TITLE (im), SZ_LINE)
	call amovr (Memr[OUT_PIX (outspec)], Memr[impl1r (im, 1)],
	     	    OUT_NPIX (outspec))
	ids = IN_IDS (inspec[1])
	NP1 (ids) = 0
	NP2 (ids) = OUT_NPIX (outspec)
	W0 (ids)  = OUT_W0 (outspec)
	WPC (ids) = OUT_WPC (outspec)
	call store_keywords (ids, im)
	call imunmap (im)

	# Write weights image if the image name is not null
	if (strne (wtname, "")) {
	    im = immap (wtname, NEW_IMAGE, 0)
	    IM_NDIM (im) = 1
	    IM_LEN (im, 1) = OUT_NPIX (outspec)
	    IM_PIXTYPE (im, 1) = TY_REAL
	    call sprintf (IM_TITLE (im), SZ_LINE, "Weighting array for %s")
		call pargstr (outname)
	    call amovr (Memr[OUT_WTPIX (outspec)], Memr[impl1r (im, 1)],
			OUT_NPIX (outspec))
	    call store_keywords (ids, im)
	    call imunmap (im)
	}
end
