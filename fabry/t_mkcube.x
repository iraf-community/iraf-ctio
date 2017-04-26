# MKCUBE -- Build a 3 dimensional cube from the	N two-dimensional
#	    images. Adds the XSHIFT and YSHIFT parameters from
#	    the 2D image headers, and	adds the Etalon	Z values
#	    as input from the	user.

include	<imio.h>
include	<imhdr.h>

# Allow	for plenty of header space since we will be adding many
# parameters - roughly 8 per band.

define	EXTRA_SPACE	((80*100)/SZ_STRUCT)

procedure	t_mkcube()

char	cube_image[SZ_FNAME]
char	image2d[SZ_FNAME]
int	infile, nfiles
int	zlist, nz

char	zstring[SZ_FNAME]
int	npix, npixold, nlines, nlinesold
int	i, nimage, stat
real	z
pointer	bufcube, buf2d,	imcube,	im2d
bool	verbose, zhdr

int	clpopni(), clplen(), clgfil()
int	imgl2s()
int	impl3s()
int	sscan()
bool	clgetb()
pointer	immap()

begin
	# Get input images names
	infile	= clpopni ("images")
	nfiles	= clplen (infile)

	# Get output cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Get Etalon values for inout images names
	zlist = clpopni ("et_gap")
	nz    = clplen	(zlist)

	zhdr =	false
	if (nz	== 0)
	    zhdr = true
	else if (nz < nfiles)
	    call error	(0, "Not enough	etalon values")

	# Print progress?
	verbose = clgetb ("verbose")


	# Copy	each image.
	nimage	= 0
	while (clgfil (infile,	image2d, SZ_FNAME) != EOF) {
	    iferr (im2d = immap (image2d, READ_ONLY, 0)) {
		call eprintf ("Cannot	open image %s\n")
		    call pargstr (image2d)
		call error (0, "")
	    }

	    nimage = nimage + 1
	    npix   = IM_LEN(im2d, 1)
	    nlines = IM_LEN(im2d, 2)

	    # If verbose print	the operation.
	    if	(verbose) {
		call eprintf ("%s -> %s\n")
		    call pargstr (image2d)
		    call pargstr (cube_image)
	    }

	    # Map the output image. Copy the first image header.
	    # Assume TY_SHORT for now to minimize disk	space.
	    # We will also assume that	all input images have identical
	    # dimensions so that a cube makes some sense.
	    #
	    # Allocate	lots of	image header space - we'll need	it later!

	    if	(nimage	== 1) {
		#imcube = immap (cube_image, NEW_IMAGE, 4*MIN_LENUSERAREA)
		imcube = immap (cube_image, NEW_COPY, im2d)
		npixold = npix
		nlinesold = nlines

#		# Copy the image header info - stolen	from imio$immaky.x
#		if (IM_LENHDRMEM(imcube) < IM_HDRLEN(im2d)) {
#		    IM_LENHDRMEM(imcube) = IM_HDRLEN(im2d) + EXTRA_SPACE
#		    call realloc (imcube, IM_LENHDRMEM(imcube) + LEN_IMDES,
#			TY_STRUCT)
#		}
#		call amovi (IM_MAGIC(im2d), IM_MAGIC(imcube),
#			IM_HDRLEN(im2d) + 1)

		IM_NDIM(imcube)  = 3
		IM_LEN(imcube,1) = npix
		IM_LEN(imcube,2) = nlines
		IM_LEN(imcube,3) = nfiles
		IM_PIXTYPE(imcube) = TY_SHORT

	    # Verify image sizes are consistent, but go ahead using
	    # first image sizes anyway. Could be trouble later.
	    } else {
		if (npix != npixold) {
		    call eprintf ("Column length of %s different\n")
			call	pargstr	(image2d)
		} else if (nlines != nlinesold) {
		    call eprintf ("Number of rows of %s different\n")
			call	pargstr	(image2d)
		}
	    }


	    # Issue warning of	pixel conversion
	    if	(IM_PIXTYPE(im2d) != TY_SHORT) {
		call eprintf ("%s pixels not SHORT - conversion will occur\n")
		    call pargstr (image2d)
	    }

	    # Copy the	pixels a line at a time
	    do	i = 1, min (nlines, nlinesold) {
		buf2d	  = imgl2s (im2d,   i)
		bufcube = impl3s (imcube, i, nimage)
		call amovs (Mems[buf2d], Mems[bufcube], npixold)
	    }

	    # Copy the	shift parameters and etalon z-value from 2d header
	    # into new	header

	    if	(!zhdr)
	    	if (clgfil (zlist, zstring, SZ_FNAME) != EOF) {
		    stat = sscan (zstring)
		    	call gargr (z)
		    if (abs(z) > 5)
		    	z = z/1000.0
	    	}	else
		    z	= 0.000

	    # Update the cube image header
	    call hdr_update (im2d, image2d, imcube, z,	nimage)
	    call imunmap (im2d)
	}

	# Unmap the cube
	call imunmap (imcube)
end

# HDR_UPDATE --	Take the shift parameters from the 2d image and
#		add them to the cube	header,	appending the 2	digit band
#		number to the parameter name: XSHIFT	--> XSHIFT01

procedure hdr_update (im2d, image2d, imcube, z,	band)

pointer	im2d, imcube
char	image2d[SZ_FNAME]
int	band
real	z

char	image2dn[SZ_FNAME], xshn[SZ_FNAME], yshn[SZ_FNAME], etan[SZ_FNAME]
real	xshift, yshift, etalon

real	get_hdrr()

begin
	# Get values from current 2d image
	xshift	= get_hdrr (im2d, "XSHIFT")
	if (xshift == INDEFR)
	    xshift = 0.0

	yshift	= get_hdrr (im2d, "YSHIFT")
	if (yshift == INDEFR)
	    yshift = 0.0

	etalon	= get_hdrr (im2d, "FPZ")
	if (etalon == INDEFR)
	    etalon = z

	# Add band number to parameter	names
	call sprintf (image2dn, SZ_FNAME, "IMAGE%02d")
	    call pargi	(band)
	call sprintf (xshn, SZ_FNAME, "XSHIFT%02d")
	    call pargi	(band)
	call sprintf (yshn, SZ_FNAME, "YSHIFT%02d")
	    call pargi	(band)
	call sprintf (etan, SZ_FNAME, "FPZ%02d")
	    call pargi	(band)

	# Update header
	call ids_adds (imcube,	image2dn, image2d)
	call ids_addr (imcube,	xshn, xshift)
	call ids_addr (imcube,	yshn, yshift)
	call ids_addr (imcube,	etan, etalon)
end
