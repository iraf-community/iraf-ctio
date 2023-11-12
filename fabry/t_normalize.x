# NORMALIZE -- Take user input normalization factors, and
# add them to the CUBE image header.

include	<fset.h>
include	<imio.h>
include	<imhdr.h>

procedure t_normalize ()

char	cube_image[SZ_FNAME]
char	ch_normal[SZ_FNAME], param[SZ_FNAME]
real	normal
int	innorm, nnorm
int	nbands
int	i, stat
bool	verbose
pointer	im

int	clpopni(), clplen(), clgfil(), sscan(), nscan()
bool	clgetb()
pointer	immap()

begin
	# Get cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Open	image right away to tell user how many bands to	enter
	im = immap (cube_image, READ_WRITE, MIN_LENUSERAREA)
	nbands	= IM_LEN (im, 3)

	# Get normalization factors
	innorm	= clpopni ("factors")
	nnorm	= clplen (innorm)

	if ((nnorm > 1) && (nnorm != nbands))
	    call error	(0, "Unequal bands and factors")

	# Get verbose option
	verbose = clgetb ("verbose")

	call fseti (STDOUT, F_FLUSHNL,	YES)

	# Update each band keyword
	do i =	1, nbands {
	    if	(nnorm == 1) {
		if (i	== 1) {
		    stat = clgfil (innorm, ch_normal,	SZ_FNAME)
		    stat = sscan (ch_normal)
			call	gargr (normal)
			stat	= nscan()
		}
	    } else {
		stat = clgfil	(innorm, ch_normal, SZ_FNAME)
		stat = sscan (ch_normal)
		    call gargr (normal)
		    stat = nscan()
	    }

	    # Add value to header
	    call sprintf (param, SZ_FNAME, "NORM%02d")
		call pargi (i)
	    call ids_addr (im,	param, normal)

	    if	(verbose) {
		call printf ("%s = %7.3f added\n")
		    call pargstr (param)
		    call pargr (normal)
	    }
	}

	call imunmap (im)
end
