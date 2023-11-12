# ZEROPT -- Zero point for lambda, Xc, and Yc are added	to the cube header
#
# The dispersion equation file for the etalon position,	and the	output
# from RINGPARS	for the	neons for the image cube are used to update
# the image cube header	for each band.

include	<fset.h>
include	<imio.h>
include	<imhdr.h>

define		MAX_RANGES	100	# Stolen	from ONEDSPEC

procedure t_zeropt ()

char	cube_image[SZ_FNAME]
char	dispersion[SZ_FNAME], neon_pars[SZ_FNAME]
char	neon_name[SZ_FNAME]
char	param1[SZ_FNAME], param2[SZ_FNAME], param3[SZ_FNAME]
char	rec_numbers[SZ_FNAME]
int	records[3, MAX_RANGES]
int	nrecs, next_band, stat
int	nbands, nneon
int	fd_neon, fd_disp
int	i
real	istd_lambda, iz, iradius, ixc, iyc, coef[3]
pointer	im, sp,	lambda,	xc, yc

int	decode_ranges(), get_next_entry()
int	fscan(), nscan(), open()
real	lambda0()
pointer	immap()

begin
	call fseti (STDOUT, F_FLUSHNL,	YES)

	# Get cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Get solution	file
	call clgstr ("dispersion", dispersion,	SZ_FNAME)

	# Get Neon parameter file
	call clgstr ("neon_pars", neon_pars, SZ_FNAME)

	# Open	image right away to tell user how many bands to	enter
	im = immap (cube_image, READ_WRITE, 4*MIN_LENUSERAREA)
	nbands	= IM_LEN (im, 3)
	call printf ("%s has %d bands\n")
	    call pargstr (cube_image)
	    call pargi	(nbands)

	# Get dispersion solution
	iferr (fd_disp	= open (dispersion, READ_ONLY, TEXT_FILE))
	    call error	(0, "Cannot open dispersion solution file")

	# Read	solution
	stat =	fscan (fd_disp)
	    call gargr	(coef[1])
	    call gargr	(coef[2])
	    call gargr	(coef[3])
	    if	(nscan() != 3)
		call error (0, "Error	reading	dispersion coefficients")

	call close (fd_disp)

	# Open	neon file and prompt user
	iferr (fd_neon	= open (neon_pars, READ_ONLY, TEXT_FILE))
	    call error	(0, "Cannot open neon parameter	file")

	# Get space for lambda, xc, yc
	call smark (sp)

	# Array lambda	will be	used initially for radius
	call salloc (lambda, nbands, TY_REAL)
	call salloc (xc    , nbands, TY_REAL)
	call salloc (yc    , nbands, TY_REAL)

	# Initialize lambda array as a	flag
	call amovkr (INDEFR, Memr[lambda], nbands)

	# Read	file and get band ranges
	nneon = 0
	while (fscan (fd_neon)	!= EOF)	{
	    nneon = nneon + 1
	    call gargr	(istd_lambda)
	    call gargr	(iz)
	    call gargr	(iradius)
	    call gargr	(ixc)
	    call gargr	(iyc)
	    call gargstr (neon_name, SZ_FNAME)

	    if	(nscan() == 6) {
		call unwhite (neon_name)
		call printf ("For Neon %s: ")
		    call pargstr (neon_name)
		call flush (STDOUT)

		call clgstr ("bands",	rec_numbers, SZ_FNAME)
		if (decode_ranges (rec_numbers, records, MAX_RANGES,
			nrecs) != ERR)

		# Required initialization
		next_band = 0
		call rst_get_entry

		# Work thru each band, updating header arrays
		while	(get_next_entry	(records, next_band) !=	EOF) {
		    if (next_band < 1	|| next_band > nbands)
			call	error (0, "Invalid band	number")

		    #	Load current parameters	for the	bands
		    Memr[lambda+next_band-1] = lambda0 (istd_lambda, iz,
			iradius, coef)
		    Memr[xc	 +next_band-1] = ixc
		    Memr[yc	 +next_band-1] = iyc

		}
	    }
	}

	# Review the bands to verify that all have been filled
	do i =	1, nbands
	    if	(Memr[lambda+i-1] == INDEFR) {
		call eprintf ("Band %2d has no zero point data\n")
		    call pargi (i)
		call error(0,	"")
	    }

	# Add the dispersion coefficients
	call ids_addr (im, "COEF1", coef[1])
	call ids_addr (im, "COEF2", coef[2])
	call ids_addr (im, "COEF3", coef[3])

	# Add values for LAMBDA, XC, YC to image header
	do i =	1, nbands {

	    call sprintf (param1, SZ_FNAME, "LAMBDA%02d")
		call pargi (i)
	    call ids_addr (im,	param1,	Memr[lambda+i-1])

	    call sprintf (param2, SZ_FNAME, "XC%02d")
		call pargi (i)
	    call ids_addr (im,	param2,	Memr[xc+i-1])

	    call sprintf (param3, SZ_FNAME, "YC%02d")
		call pargi (i)
	    call ids_addr (im,	param3,	Memr[yc+i-1])

	    call printf ("%s =	%8.2f	%s = %8.2f   %s	= %8.2f	 added\n")
		call pargstr (param1)
		call pargr (Memr[lambda+i-1])
		call pargstr (param2)
		call pargr (Memr[xc+i-1])
		call pargstr (param3)
		call pargr (Memr[yc+i-1])
	}

	call sfree (sp)
	call close (fd_neon)
	call imunmap (im)
end

# LAMBDA0 -- Compute lambda0 from the radius and the dispersion	coefficients

real procedure lambda0 (std_lambda, z, radius, coef)

real	std_lambda, z, radius, coef[3]

real	temp1
real	cos(), atan()

begin
	# Compute the first coefficient - lambda 0 - for
	# the current parameters, based on:
	# Lambda = (c[1] + z*c[2]) * (cos (atan (radius/c[3]))

	temp1 = cos (atan (radius/coef[3]))
	return	((std_lambda/temp1) - z*coef[2])
end
