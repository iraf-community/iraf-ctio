#FINDSKY -- Use	cube to	compute	an avergae sky intensity from several positions.
# Then update the cube header to include the sky levels	at each	band.

include	<fset.h>
include	<imio.h>
include	<imhdr.h>

# Following for	dynamic	storage
define		MAX_POS		50	# Maximum sky positions

procedure t_findsky ()

char	cube_image[SZ_FNAME], coord_file[SZ_FNAME]
char	param[SZ_FNAME]
int	x, y, x1, x2, y1, y2
int	fd,	i
int	navgx, navgy, nbands, ncoords, nx, ny
bool	verbose, okay
pointer	sky, avgsky, sigsky, im, buf, sp, work

int	fscan(), nscan(), open()
int	clgeti()
real	clgetr()
bool	clgetb()
pointer	immap(), imgs3s()

begin
	# Get cube name
	call clgstr ("cube_image", cube_image,	SZ_FNAME)

	# Get coordinate file
	call clgstr ("coord_file", coord_file,	SZ_FNAME)

	# Get averging	parameters
	navgx = clgeti	("navgx")
	navgy = clgeti	("navgy")

	# Get verbose option
	verbose = clgetb ("verbose")

	call fseti (STDOUT, F_FLUSHNL,	YES)

	# Open	image
	im = immap (cube_image, READ_WRITE, 4*MIN_LENUSERAREA)
	nbands	= IM_LEN (im, 3)

	# Get some space for 2D arrays	sky[band,pos]
	call smark (sp)
	call salloc (sky   , nbands*MAX_POS, TY_REAL)
	call salloc (sigsky, nbands	    , TY_REAL)
	call salloc (avgsky, nbands	    , TY_REAL)
	call salloc (work  , MAX_POS	    , TY_REAL)

	# Open	coordinate file
	iferr (fd = open (coord_file, READ_ONLY, TEXT_FILE))
	    call error	(0, "Cannot open coordinate file")

	# Cycle thru all coordinates
	ncoords = 0
	while (fscan (fd) != EOF) {
	    call gargi	(x)
	    call gargi	(y)
	    if	(nscan() == 2) {

		ncoords = ncoords + 1

		# Define extraction region
		x1 = x - navgx/2
		x2 = x + navgx/2
		nx = x2 - x1 + 1

		y1 = y - navgy/2
		y2 = y + navgy/2
		ny = y2 - y1 + 1

		# Extract the	subraster
		buf =	imgs3s (im, x1,	x2, y1,	y2, 1, nbands)

		# Block average the buffer
		call blksky (Mems[buf], nx, ny, nbands, ncoords, Memr[sky])
	    }
	}

	# Compute the sigma if	enough coords available
	if (ncoords > 1)
	    call calcsig (Memr[sky], nbands, ncoords, Memr[avgsky],
		Memr[sigsky],	Memr[work])
	else
	    call amovkr (0.0, Memr[sigsky], nbands)

	# Print results
	do i =	1, nbands {
	    call printf ("Sky,	sigma for Band %2d: %8.1f, %8.1f\n")
		call pargi (i)
		call pargr (Memr[avgsky+i-1])
		call pargr (Memr[sigsky+i-1])
	}

	# Allow user to override
	if (verbose) {
	    do	i = 1, nbands {
		call printf ("Band %2d: %8.1f, %8.1f	")
		    call pargi (i)
		    call pargr (Memr[avgsky+i-1])
		    call pargr (Memr[sigsky+i-1])
		call flush (STDOUT)

		okay = clgetb	("okay")
		if (!okay)
		    Memr[avgsky+i-1] = clgetr	("sky")
	    }
	}

	# Add values to header
	do i =	1, nbands {
	    call sprintf (param, SZ_FNAME, "SKY%02d")
		call pargi (i)
	    call ids_addr (im,	param, Memr[avgsky+i-1])
	}


	call sfree (sp)
	call close (fd)
	call imunmap (im)
end

# BLKSKY -- Block average the extracted	buffer into the	sky array

procedure blksky (buf, nx, ny, nbands, ncoord, sky)

short	buf[nx, ny, nbands]
real	sky[nbands, ARB]
int	nx,	ny, nbands, ncoord

int	i, j, k
real	sum

begin
	do i =	1, nbands {
	    sum = 0.0
	    do	k = 1, ny
		do j = 1, nx
		    sum = sum	+ buf[j,k,i]

	    sky[i,ncoord] = (sum+0.5) / (nx*ny)
	}
end

# CALCSIG -- Compute sigma of the sky

procedure calcsig (sky,	nbands,	ncoords, avgsky, sigsky, work)

real	sky[nbands, ARB], avgsky[ARB], sigsky[ARB], work[ARB]
int	nbands, ncoords

int	i, j

begin
	do i =	1, nbands {
	    do	j = 1, ncoords
		work[j] = sky[i, j]

	    call aavgr	(work, ncoords,	avgsky[i], sigsky[i])
	}
end
