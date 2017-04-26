include	<imhdr.h>
include	<error.h>
include	<mach.h>
include	<fset.h>
include	<gset.h>

define	MAX_ITER	2	# Number of centroiding iterations to	do


# RINGPARS -- Determine	the centers and	radius of a circle
#		by making row and column cuts iteratively.

procedure t_ringpars()

char	in_image[SZ_FNAME], output[SZ_FNAME], lzfile[SZ_FNAME]
int	nfiles, infile
int	navg, index, nxavg
int	xstart, ystart, i, j, xstart_prev
int	nrows, ncols, buflen, separation, edge, nmax, nfound
int	count, xs, ys, npts_cntr
int	fdout, fdlz
real	contrast, thresh, yminc, ymaxc, xminc, xmaxc, xc, yc, radius
real	lambda, z
bool	debug, verbose, lz_from_file, interactive
pointer	xpos, im, avgbuf, dblbuf, sp, spim, avgcol, colsect, v

int	clgeti(), clpopni(), clplen(), clgfil(), find_peaks(), open()
int	strlen()
real	clgetr()
bool	clgetb()
pointer	imgl2r(), immap(), imgs2r()

begin
	# Get image names
	infile	= clpopni ("input")
	nfiles	= clplen (infile)

	# Get output file name
	call clgstr ("output",	output,	SZ_FNAME)

	# User	must input lambda and z, the etalon spacing until
	# these are available in the image header
	lambda	= clgetr ("lambda")
	z	= clgetr ("z")

	# User	may input telescope values
	if (abs (z) > 5)
	    z = z / 1000.0

	# Or optionally may come from a file
	if (lambda == 0.0) {
	    lz_from_file = true
	    call clgstr ("lzfile", lzfile, SZ_FNAME)

	    if	(strlen	(lzfile) == 0)
		call error (0, "Must specify either lzfile or	lambda/z")

	    iferr (fdlz = open	(lzfile, READ_ONLY, TEXT_FILE))	{
		call eprintf ("Cannot open lambda/z file %s\n")
		    call pargstr (lzfile)

		call error (0, "Need info on lambda/z")
	    }
	} else
	    lz_from_file = false

	# Number to average in	both rows and cols
	navg =	clgeti ("average")

	# Starting row	and column
	xs = clgeti ("xstart")
	ys = clgeti ("ystart")

	# Get nr of points to use in centroider
	npts_cntr = clgeti ("cwidth")

	# Find	peaks parameters
	contrast   = clgetr ("contrast")
	separation = clgeti ("separation")
	thresh	    = clgetr ("threshold")

	# Answers wanted on terminal, too?
	verbose = clgetb ("verbose")

	# Use graphics?
	interactive = clgetb ("interactive")

	# Define constants for	find_peaks...these may become parameteres later
	edge	    = 10
	nmax	    = 2
	debug	    = false

	# Force output	on Newline
	call fseti (STDOUT, F_FLUSHNL,	YES)

	# Allocate space for centroider
	call smark (sp)
	call salloc (v, npts_cntr, TY_REAL)

	# Open	output answer file
	iferr (fdout =	open (output, APPEND, TEXT_FILE)) {
	    call eprintf ("cannot open	output file %s\n")
		call pargstr (output)
	}

	# Open	input image
	while (clgfil (infile,	in_image, SZ_FNAME) != EOF) {
	    iferr (im = immap (in_image, READ_ONLY, 0)) {
		call eprintf ("[%s] not found\n")
		call pargstr (in_image)
		go to	10
	    }

	    # Get lambda and z	if necessary
	    if	(lz_from_file)
		call getlz (fdlz, lambda, z)

	    count = 0
	    xstart_prev = -1

	    ncols = IM_LEN (im, 1)
	    nrows = IM_LEN (im, 2)
	    buflen = max (nrows, ncols)

	    # Hold space for averaging	of rows
	    call smark	(spim)
	    call salloc (avgbuf, ncols, TY_REAL)
	    call salloc (avgcol, nrows, TY_REAL)
	    call salloc (xpos,	  buflen, TY_DOUBLE)

	    # Hold space for FIND_PEAKS routine which wants a double
	    call salloc (dblbuf, buflen, TY_DOUBLE)

	    # Assume a	start near the middle
	    if	(ys == 0)
		ystart = nrows / 2
	    else
		ystart = ys

	    if	(xs == 0)
		xstart = ncols / 2
	    else
		xstart = xs

	    # Iterate to get best row and column cuts
	    repeat {
		 # Get max and min y-values based on a column cut
		# if (xstart !=	xstart_prev)
		     colsect = imgs2r (im, xstart-navg/2, xstart+navg/2, 1,
				nrows)

		xstart_prev =	xstart
		nxavg	= 2 * (navg/2) + 1

		 # Average the columns
		 call aclrr (Memr[avgcol], nrows)
		 call colavg (Memr[colsect], Memr[avgcol], nxavg, nrows)

		 # Move	to double precision
		 do j =	1, nrows
		    Memd[dblbuf+j-1] = Memr[avgcol+j-1]

		 # Find	peaks
		 nfound	= find_peaks (Memd[dblbuf], Memd[xpos],	nrows,
			 contrast, separation, edge,	nmax, thresh, debug)
		 call pkcntr (Memd[dblbuf], Memd[xpos]	, Memr[v],
		    npts_cntr, yminc)
		 call pkcntr (Memd[dblbuf], Memd[xpos+1], Memr[v],
		    npts_cntr, ymaxc)

		 yc = 0.5 * (ymaxc + yminc)

		# Update ystart
		 ystart	= yc + 0.5

		# Now	find x-	center
		 index = ystart	- navg/2

		 call aclrr (Memr[avgbuf], ncols)

		 # Compute average of the rows
		 do j =	1, navg
		    call aaddr (Memr[imgl2r(im,index+j-1)], Memr[avgbuf],
			Memr[avgbuf], ncols)

		 do j =	1, ncols
		    Memd[dblbuf+j-1] = Memr[avgbuf+j-1] / navg

		 # Find	the peaks and load table
		 nfound	= find_peaks (Memd[dblbuf], Memd[xpos],	ncols,
		     contrast, separation, edge, nmax, thresh, debug)

		 # Center up on	the peaks
		 call pkcntr (Memd[dblbuf], Memd[xpos],	  Memr[v],
		    npts_cntr, xminc)
		 call pkcntr (Memd[dblbuf], Memd[xpos+1], Memr[v],
		    npts_cntr, xmaxc)

		# Update x-center
		 xc = 0.5 * (xmaxc + xminc)
		 xstart	= xc + 0.5

		 count = count + 1
	    } until (count == MAX_ITER)

	    # Allow user a chance to review the results graphically
	    if	(interactive) {
		do i = 1, ncols
		    Memr[avgbuf] = Memd[dblbuf]

		 call ring_plot	(in_image, Memr[avgcol], Memr[avgbuf],
		    nrows, ncols, xminc, xmaxc, yminc, ymaxc,	interactive)

		 xc = 0.5 * (xmaxc + xminc)
		 yc = 0.5 * (ymaxc + yminc)
	    }

	    # Compute radius from average in x	and y
	    radius = 0.5 * ((xmaxc-xminc)/2 + (ymaxc-yminc)/2)

     call fprintf (fdout,"%9.3f   %7.3f   %7.2f   %7.2f   %7.2f  [%s]\n")
		call pargr (lambda)
		call pargr (z)
		call pargr (radius)
		call pargr (xc)
		call pargr (yc)
		call pargstr (in_image)

	    if	(verbose) {
	    	call printf ("%9.3f   %7.3f   %7.2f   %7.2f   %7.2f  [%s]\n")
		    call pargr (lambda)
		    call pargr (z)
		    call pargr (radius)
		    call pargr (xc)
		    call pargr (yc)
		    call pargstr (in_image)
	    }

	    call sfree	(spim)
	    call imunmap (im)
10	    ;
	}

	call close (fdlz)
	call close (fdout)
	call sfree (sp)

	end

# PKCNTR -- Find center	of peak	using MPC algorithm

procedure pkcntr (data,	approx,	v, npts_cntr, pos)

double	data[ARB], approx
real	v[ARB]
real	pos
int	npts_cntr

int	i

begin
	# Copy	data into Real array
	do i =	1, npts_cntr
	    v[i] = data[int(approx+i-1-npts_cntr/2)]

	call getcenter	(v, npts_cntr, pos)
	pos = pos + approx - npts_cntr/2
end

# GETCENTER -- Compute centroid

procedure getcenter (v,	nv, vc)

real	v[ARB]
int	nv
real	vc

int	i
real	sum1, sum2, sigma,	cont

begin
	# Assume continuum level is at	endpoints
	# Compute first moment
	sum1 =	0.0
	sum2 =	0.0

	call aavgr (v,	nv, cont, sigma)

	do i =	1, nv
	    if	(v[i] >	cont) {
		 sum1 =	sum1 + (i-1) * (v[i] - cont)
		 sum2 =	sum2 + (v[i] - cont)
	    }

	# Determine center
	vc = sum1 / sum2
end

# COLAVG -- Average columns from subraster

procedure colavg (colsect, avgcol, ncols, nrows)

real	colsect[ncols, nrows], avgcol[nrows]
int	ncols, nrows

int	i, j
real	temp

begin
	do i =	1, nrows {
	    temp = 0.0

	    do	j = 1, ncols
		temp = temp +	colsect[j,i]

	    avgcol[i] = temp /	ncols
	}
end

# GETLZ	-- Read	lambda and z from file.	Convert	z to near 1.000	if
#	   user entered in telescope units near 1000.0

procedure getlz	(fd, lambda, z)

int	fd
real	lambda, z

int	stat

int	fscan(), nscan()

begin
	# Scan	next line
	stat =	fscan (fd)

	if (stat == EOF)
	    call error	(0, "Prematurely out of	data in	lambda/z file")

	call gargr (lambda)
	call gargr (z)

	if (nscan() < 2)
	    call error	(0, "Insufficient values in lambda/z file")

	if (abs (z) > 5)
	    z = z / 1000.0
end

# RING_PLOT -- Generate	plots of rows and columns for the user to review
#		and optionally override the derived values

procedure ring_plot (im_name, avgcol, avgrow, nrows, ncols, xminc, xmaxc,
		yminc, ymaxc,	interactive)

char	im_name[SZ_FNAME]
int	nrows, ncols
real	avgcol[ARB], avgrow[ARB]
real	xminc, xmaxc, yminc, ymaxc
bool	interactive

int	key, gp
real	x1, x2, y1, y2

int	gopen()

begin
	# Open	plot device and	clear screen
	gp = gopen ("stdgraph", NEW_FILE, STDGRAPH)

	# Clear screen
	call gclear (gp)

	# Set minor ticks off
	call gseti (gp, G_NMINOR, 0)

	# Plot	data array - Row first
	x1 = 1.0
	x2 = ncols
	call gswind  (gp, x1, x2, INDEF, INDEF)
	call gascale (gp, avgrow, ncols, 2)
	call glabax  (gp, im_name, "Column Number", "")
	call gvline  (gp, avgrow, ncols, x1, x2)

	# Plot	current	centers
	y1 = 1.1 * avgrow[int(xminc+0.5)]
	y2 = y1 * 0.7
	call gline (gp, xminc,	y1, xminc, y2)

	y1 = 1.1 * avgrow[int(xmaxc+0.5)]
	y2 = y1 * 0.7
	call gline (gp, xmaxc,	y1, xmaxc, y2)

	# Turn	on cursor and request better values
	call guser (gp, xminc,	xmaxc, key)

	if (key == 'i') {
	    interactive = false
	    call gclose (gp)
	    return
	}

	# Plot	data array - Columns now
	call gclear (gp)

	# Set minor ticks off
	call gseti (gp, G_NMINOR, 0)

	x1 = 1.0
	x2 = nrows
	call gswind  (gp, x1, x2, INDEF, INDEF)
	call gascale (gp, avgcol, nrows, 2)
	call glabax  (gp, im_name, "Row Number", "")
	call gvline  (gp, avgcol, nrows, x1, x2)

	# Plot	current	centers
	y1 = 1.1 * avgcol[int(yminc+0.5)]
	y2 = y1 * 0.7
	call gline (gp, yminc,	y1, yminc, y2)

	y1 = 1.1 * avgcol[int(ymaxc+0.5)]
	y2 = y1 * 0.7
	call gline (gp, ymaxc,	y1, ymaxc, y2)

	# Turn	on cursor and request better values
	call guser (gp, yminc,	ymaxc, key)

	if (key == 'i')
	    interactive = false

	call gclose (gp)
end

# GUSER	-- Graphics user input

procedure guser	(gp, vlow, vhigh, key)

int	gp,	key
real	vlow, vhigh

char	command[SZ_FNAME]
int	stat
real	wx, wy, wc

int	clgcur()

begin
	# Turn	on cursor
	repeat	{
	    stat = clgcur ("cursor", wx, wy, wc, key, command,	SZ_FNAME)

	    if	(stat == EOF) {
		 key = 'q'
		 return
	    }

	    switch (key) {
	    # Help
	    case '/','?':
		call gdeactivate (gp,	0)
		call printf ("l=set_low  h=set_hi  i=no_interact  ")
		call printf ("c=cur_pos  v=cur_vals  q=quit")
		call greactivate (gp,	0)

	    # Interactive off
	    case 'i':
		return

	    # Set new low value
	    case 'l':
		call gdeactivate (gp,	0)
		call printf ("Low value was: %9.3f  --  Set to: %9.3f")
		call pargr (vlow)
		call pargr (wx)
		call greactivate (gp,	0)
		vlow = wx

	    # Set new high value
	    case 'h':
		call gdeactivate (gp,	0)
		call printf ("Low value was: %9.3f  --  Set to: %9.3f")
		call pargr (vhigh)
		call pargr (wx)
		call greactivate (gp,	0)
		vhigh	= wx

	    # Print cursor position
	    case ' ', 'c':
		call gdeactivate (gp,	0)
		call printf ("%9.3f  %9.3f")
		call pargr (wx)
		call pargr (wy)
		call greactivate (gp,	0)

	    # Print current values for	high and low
	    case 'v':
		call gdeactivate (gp,	0)
		call printf ("low=%9.3f   high=%9.3f")
		call pargr (vlow)
		call pargr (vhigh)
		call greactivate (gp,	0)
	    }

	    call flush	(STDOUT)

	} until (key == 'q')
end
