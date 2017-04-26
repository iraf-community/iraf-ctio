include	<imhdr.h>

# Header types
define	HEADER_TYPES	"|new|copy|"
define	HEADER_NEW	1
define	HEADER_COPY	2

# Pixel types
define	PIXEL_TYPES	"|reference|ushort|short|int|long|real|double|complex|"
define	PIXEL_REFERENCE	1
define	PIXEL_USHORT	2
define	PIXEL_SHORT	3
define	PIXEL_INT	4
define	PIXEL_LONG	5
define	PIXEL_REAL	6
define	PIXEL_DOUBLE	7
define	PIXEL_COMPLEX	8


# T_IMCREATE -- Create an image of arbitrary dimension. The header can
# be copied from a reference image, or set to the minimum set. The output
# pixel type can be set also from a reference image, or explicitly. All
# the pixels in the image are initialized to zero.

procedure t_imcreate ()

char	output[SZ_FNAME]		# output image name
char	reference[SZ_FNAME]		# reference image name
char	str[SZ_LINE]
int	header				# output image header mode
int	ndim				# number of axes
int	naxis[IM_MAXDIM]		# axis lengths
int	pixtype				# pixel type
int	i
long	v[IM_MAXDIM]
pointer	outim, refim			# image descriptors
pointer	lineptr				# line pointer

int	clgeti(), clgwrd()
int	imgeti()
pointer	immap()
pointer	impnls(), impnll(), impnlr(), impnld(), impnlx()

begin
	# Get output image name and number of axes
	call clgstr ("image", output, SZ_FNAME)

	# Get number of axes, and axis lengths
	ndim = min (clgeti ("naxis"), IM_MAXDIM)
	do i = 1, ndim {
	    call sprintf (str, SZ_LINE, "naxis%d")
		call pargi (i)
	    naxis[i] = clgeti (str) 
	}

	# Get pixel type, and convert it into an SPP type if
	# possible. Otherwise leave it undefined in order to
	# get it from the reference image.
	switch (clgwrd ("pixtype", str, SZ_LINE, PIXEL_TYPES)) {
	case PIXEL_REFERENCE:
	    pixtype = INDEFI
	case PIXEL_USHORT:
	    pixtype = TY_USHORT
	case PIXEL_SHORT:
	    pixtype = TY_SHORT
	case PIXEL_INT:
	    pixtype = TY_INT
	case PIXEL_LONG:
	    pixtype = TY_LONG
	case PIXEL_REAL:
	    pixtype = TY_REAL
	case PIXEL_DOUBLE:
	    pixtype = TY_DOUBLE
	case PIXEL_COMPLEX:
	    pixtype = TY_COMPLEX
	default:
	    call error (0, "Unknown pixel type")
	}

	# Get output image header mode, and reference image name
	header = clgwrd ("header", str, SZ_LINE, HEADER_TYPES)
	call clgstr ("reference", reference, SZ_LINE)

	# Open reference image either if the output image header
	# should be a copy of the reference image header, or if
	# the pixel type is undefined (reference).
	if (header == HEADER_COPY || IS_INDEFI (pixtype))
	    refim = immap (reference, READ_ONLY, 0)
	else
	    refim = NULL

	# Get pixel type from reference image if it's still undefined
	if (IS_INDEFI (pixtype))
	    pixtype = imgeti (refim, "i_pixtype")

	# Open output image according to the header copy mode
	if (header == HEADER_COPY)
	    outim = immap (output, NEW_COPY, refim)
	else
	    outim = immap (output, NEW_IMAGE, 0)

	# Update output image header. This is the minimum
	# information that's always set.
	call imputi (outim, "i_pixtype", pixtype)
	call imputi (outim, "i_naxis", ndim)
	do i = 1, ndim {
	    call sprintf (str, SZ_LINE, "i_naxis%d")
		call pargi (i)
	    call imputi (outim, str, naxis[i])
	}

	# Clear pixel values
	call amovkl (long (1), v, IM_MAXDIM)
	switch (pixtype) {
	case TY_SHORT:
	    while (impnls (outim, lineptr, v) != EOF)
	        call aclrs (Mems[lineptr], naxis[1])
	case TY_USHORT, TY_INT, TY_LONG:
	    while (impnll (outim, lineptr, v) != EOF)
		call aclrl (Meml[lineptr], naxis[1])
	case TY_REAL:
	    while (impnlr (outim, lineptr, v) != EOF)
		call aclrr (Memr[lineptr], naxis[1])
	case TY_DOUBLE:
	    while (impnld (outim, lineptr, v) != EOF)
		call aclrd (Memd[lineptr], naxis[1])
	case TY_COMPLEX:
	    while (impnlx (outim, lineptr, v) != EOF)
		call aclrx (Memx[lineptr], naxis[1])
	default:
		call error (0, "Unknown output pixel type")
	}

	# Ummap images
	if (refim != NULL)
	    call imunmap (refim)
	call imunmap (outim)
end
