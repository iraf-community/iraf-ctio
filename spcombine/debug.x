include	<imhdr.h>
include	"idsmtn.h"
include "spcombine.h"


# DEBUG_IN - Print input spectra structure

procedure debug_in (spectra, nspec)

pointer	spectra[ARB]
int	nspec

int	i
pointer ptr

begin
	call eprintf ("debug_in: nspec=<%d>\n")
	    call pargi (nspec)

	do i = 1, nspec {
	    ptr = spectra[i]
	    call eprintf ("%2.2d ptr=<%d> im=<%d> ids=<%d> iw0=<%g> iwpc=<%g> inpix=<%d> iexp=<%d>\n")
		call pargi (i)
		call pargi (ptr)
	        call pargi (IN_IM (ptr))
	        call pargi (IN_IDS (ptr))
	        call pargr (W0 (IN_IDS (ptr)))
	        call pargr (WPC (IN_IDS (ptr)))
	        call pargi (IM_LEN (IN_IM (ptr), 1))
	        call pargi (ITM (IN_IDS (ptr)))
	    call eprintf ("   w0=<%g> w1=<%g> wpc=<%g> npix=<%d> wt=<%g> pix=<%d>\n")
		call pargr (IN_W0 (ptr))
		call pargr (IN_W1 (ptr))
		call pargr (IN_WPC (ptr))
		call pargi (IN_NPIX (ptr))
		call pargr (IN_WT (ptr))
		call pargi (IN_PIX (ptr))
	}
end


# DEBUG_OUT - Print output spectrum structure

procedure debug_out (spectrum)

pointer	spectrum

begin
	call eprintf ("debug_out: spectrum=<%d>\n")
	    call pargi (spectrum)

	call eprintf ("w0=<%g> w1=<%g> wpc=<%g> npix=<%d> log=<%b> flux=<%b> mode=<%d> pix=<%d> wtpix=<%d>\n")
	    call pargr (OUT_W0 (spectrum))
	    call pargr (OUT_W1 (spectrum))
	    call pargr (OUT_WPC (spectrum))
	    call pargi (OUT_NPIX (spectrum))
	    call pargb (OUT_LOG (spectrum))
	    call pargi (OUT_PIX (spectrum))
	    call pargi (OUT_WTPIX (spectrum))
end

# DUMP_IN - Dump the input spectra into text files

procedure dump_in (spectra, nspec)

pointer	spectra[ARB]
int	nspec

char	name[SZ_FNAME]
int	i, j ,fd
pointer	ptr

int	open()

begin
	call eprintf ("dump_in: spectra=<%d> nspec=<%d>\n")
	    call pargi (spectra)
	    call pargi (nspec)

	do i = 1, nspec {

	    ptr = spectra[i]

	    if (IN_PIX (ptr) == NULL)
		 next

	    call sprintf (name, SZ_FNAME, "data%d")
		call pargi (i)

	    call eprintf ("...writing %s\n")
		call pargstr (name)

	    fd = open (name, WRITE_ONLY, TEXT_FILE)

	    do j = 1, IN_NPIX (ptr) {
		call fprintf (fd, "%d %g\n")
		    call pargi (j)
		    call pargr (Memr[IN_PIX (ptr) + j - 1])
	    }

	    call close (fd)
	}
end


# DUMP_OUT - Dump the output and weights spectra into a texts files

procedure dump_out (spectrum)

pointer	spectrum

int	j ,fd
int	open()

begin
	call eprintf ("dump_out: spectrum=<%d>\n")
	    call pargi (spectrum)

	if (OUT_PIX (spectrum) != NULL) {

	    call eprintf ("...writing dataout\n")

	    fd = open ("dataout", WRITE_ONLY, TEXT_FILE)

	    do j = 1, OUT_NPIX (spectrum) {
	        call fprintf (fd, "%d %g\n")
	            call pargi (j)
	            call pargr (Memr[OUT_PIX (spectrum) + j - 1])
	    }

	    call close (fd)
	}

	if (OUT_WTPIX (spectrum) != NULL) {

	    call eprintf ("...writing datawt\n")

	    fd = open ("datawt", WRITE_ONLY, TEXT_FILE)

	    do j = 1, OUT_NPIX (spectrum) {
	        call fprintf (fd, "%d %g\n")
	            call pargi (j)
	            call pargr (Memr[OUT_WTPIX (spectrum) + j - 1])
	    }

	    call close (fd)
	}
end
