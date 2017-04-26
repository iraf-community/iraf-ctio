include	<math.h>
include	<error.h>

# Memory allocation increment for standard stars and unknown stars.
# These quantities define the memory increments, in double precision
# numbers, for the buffers to hold the data for all the stars.
define	STD_INC		100
define	STAR_INC	200

# Output titles
define	TITLE1	"            Input coordinates               Output coordinates        Diff.\n"
define	TITLE2 "    x      y        ra          dec           ra          dec       ra     dec\n"
define	TITLE3	"\n       Solution for coordinates\n"
define	TITLE4	"    x      x        ra          dec\n"


# T_COORDS - Run the coordinate transformation procedure for all files
# in the input list.

procedure t_coords()

char	input[SZ_FNAME]		# input file name
char	output[SZ_FNAME]	# output file name
int	list			# input file list
int	ifd, ofd		# nput and output file descriptors

bool	streq()
int	clpopnu(), clgfil(), open()

begin
	# Get input list and output file name
	list = clpopnu ("input")
	call clgstr ("output", output, SZ_FNAME)

	# Assign standard output to output file
	# if nothing specified
	if (streq (output, ""))
	    call strcpy ("STDOUT", output, SZ_FNAME)

	# Open output file
	ofd = open (output, APPEND, TEXT_FILE)

	# Loop over input files
	while (clgfil (list, input, SZ_FNAME) != EOF) {

	    # Check if the input and output file names are
	    # the same. Skip the file if so.
	    if (streq (input, output)) {
		call eprintf (
		    "Warning: input file name = output file name (%s)\n")
		    call pargstr (input)
		next
	    }

	    # Try to open the input file. Send a warning message and
	    # skip it if it couldn't be done.
	    iferr (ifd = open (input, READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Call the coordinates procedure
	    call coords (ifd, ofd)

	    # Close input file
	    call close (ifd)
	}

	# Close output file
	call close (ofd)

	# Close input list
	call clpcls (list)
end


# COORDS - Compute celestial coordinates for a list of stars using some
# reference stars to evaluate the transformation.

procedure coords (ifd, ofd)

int	ifd, ofd		# input and output file descriptors

int	nstan			# standard stars counter
int	nstar			# unknown stars counter
int	i
real	dummy
double	p[12], u[7]
double	suma, sumd, suma2, sumd2
double	scale
double	rac, decc
double	xi1, xi2
double	eta1, eta2
double	c1, c2, c3
double	d6
double	s1, s2, s3
double	a, b, c, d, e, f
double	aa, dd, da
double	dra, ddec
double	rmsra, rmsdec
pointer	ra			# standard stars right ascentioons (rad)
pointer	dec			# standard stars declinations (rad)
pointer	x1			# standard stars x positions (pixels)
pointer	y1			# standard stars y positions (pixels)
pointer	xi
pointer	eta
pointer	x2			# unknwon stars x positions
pointer	y2			# unknown stars y positions

begin
	# Read coordinates from input file

	call coo_read (ifd, ra, dec, x1, y1, nstan, x2, y2, nstar)

	# Allocate space for XI and ETA

	call malloc (xi, nstan, TY_DOUBLE)
	call malloc (eta, nstan, TY_DOUBLE)

	# Compute center of measured area by averaging coordinates.

	suma  = 0.0
	sumd  = 0.0
	dummy = real (nstan)
	p(12) = double (dummy)

	do i = 1, nstan {
	    suma = suma + Memd[ra+i-1]
	    sumd = sumd + Memd[dec+i-1]
	}

	rac  = suma / p[12]
	decc = sumd / p[12]
	s2   = sin (decc)
	c2   = cos (decc)

	# Solve the least-square equations for the reference stars

	do i = 1, nstan {
            da     = Memd[ra+i-1] - rac
            s1     = sin (da)
            c1     = cos (da)
            s3     = sin (Memd[dec+i-1])
            c3     = cos (Memd[dec+i-1])
            d6     = s2 * s3 + c2 * c3 * c1
            Memd[xi+i-1]  = c3 * s1 / d6
            Memd[eta+i-1] = (c2 * s3 - s2 * c3 * c1) / d6
	} 

	u[7] = 0.0

	do i = 2, nstan {
            u[1] = Memd[x1+i-1] - Memd[x1+i-2]
            u[2] = Memd[y1+i-1] - Memd[y1+i-2]
            u[3] = u[1] ** 2 + u[2] ** 2
            u[4] = Memd[xi+i-1] - Memd[xi+i-2]
            u[5] = Memd[eta+i-1] - Memd[eta+i-2]
            u[6] = u[4] ** 2 + u[5] ** 2
            u[7] = u[7] + sqrt (u[3] / u[6])
 	}

	u[7] = u[7] / (p[12] - 1.0)

	do i = 1, nstan {
            Memd[xi+i-1]  = u[7] * Memd[xi+i-1]
            Memd[eta+i-1] = u[7] * Memd[eta+i-1]
	}

	call aclrd (p, 11)

	do i = 1, nstan {
            p[1]  = p[1]  + Memd[x1+i-1] * Memd[x1+i-1]
            p[2]  = p[2]  + Memd[x1+i-1] * Memd[y1+i-1]
            p[3]  = p[3]  + Memd[x1+i-1]
            p[4]  = p[4]  + Memd[x1+i-1] * Memd[xi+i-1]
            p[5]  = p[5]  + Memd[y1+i-1] * Memd[y1+i-1]
            p[6]  = p[6]  + Memd[y1+i-1]
            p[7]  = p[7]  + Memd[y1+i-1] * Memd[xi+i-1]
            p[8]  = p[8]  + Memd[xi+i-1]
            p[9]  = p[9]  + Memd[x1+i-1] * Memd[eta+i-1]
            p[10] = p[10] + Memd[y1+i-1] * Memd[eta+i-1]
            p[11] = p[11] + Memd[eta+i-1]
	}

	call coo_sle3 (p[1], p[2], p[3], p[4], p[2], p[5], p[6], p[7], 
		   p[3], p[6], p[12], p[8], a, b, c)

	call coo_sle3 (p[1], p[2], p[3], p[9], p[2], p[5], p[6], p[10], 
		   p[3], p[6], p[12], p[11], d, e, f)

	# Compute new XI and ETA for the input stars and compare these to the
	# input values.

	call fprintf (ofd, "\n")
	call fprintf (ofd, TITLE1)
	call fprintf (ofd, TITLE2)

	suma = 0
	sumd = 0
	suma2 = 0
	sumd2 = 0
	do i = 1, nstan {

	    xi1  = a * Memd[x1+i-1] + b * Memd[y1+i-1] + c
            eta1 = d * Memd[x1+i-1] + e * Memd[y1+i-1] + f

	    # Convert pixel coordinates to celestial coordinates
            call coo_conv (xi1, eta1, u[7], s2, c2, rac, aa, dd)

	    # Compute differences in seconds of arc !
	    dra = RADTODEG (Memd[ra+i-1] - aa) * 3600 * cos (Memd[dec+i-1])
	    ddec = RADTODEG (Memd[dec+i-1] - dd) * 3600

	    # Print results to output file
	    call fprintf (ofd,
		"%6.1f %6.1f %12.2h %12.2h %12.2h %12.2h %6.3f %6.3f\n")
	        call pargd (Memd[x1+i-1])
	        call pargd (Memd[y1+i-1])
	        call pargd (RADTODEG (Memd[ra+i-1]) / 15)
	        call pargd (RADTODEG (Memd[dec+i-1]))
	        call pargd (RADTODEG (aa) / 15)
	        call pargd (RADTODEG (dd))
		call pargd (dra)
		call pargd (ddec)

	    # Compute sum of differences
	    suma = suma + dra
	    suma2 = suma2 + dra * dra
	    sumd = sumd + ddec
	    sumd2 = sumd2 + ddec * ddec
	}

	# Compute RMS of differences, and print them
	suma = suma / nstan
	suma2 = suma2 / nstan
	sumd = sumd / nstan
	sumd2 = sumd2 / nstan
	rmsra = sqrt (suma2  - suma * suma)
	rmsdec = sqrt (sumd2 - sumd * sumd)
	call fprintf (ofd,
	    "\nRMS in arcsec:  ra = %6.3f,  dec = %6.3f,  total = %6.3f\n")
	    call pargd (rmsra)
	    call pargd (rmsdec)
	    call pargd (sqrt (rmsra * rmsra + rmsdec * rmsdec))

	# Compute scale factor and, print it
	scale = 206265. * atan (1.0 / real (u[7]))
	call fprintf (ofd, "\nFrame scale is %5.2f arcsec/pixel\n")
	    call pargd (scale)

	# Compute new XI and ETA for all the stars, convert these into
	# right ascension and declination, and print them
	if (nstar > 0) {

	    call fprintf (ofd, TITLE3)
	    call fprintf (ofd, TITLE4)

	    do i = 1, nstar {

                xi2  = a * Memd[x2+i-1] + b * Memd[y2+i-1] + c
                eta2 = d * Memd[x2+i-1] + e * Memd[y2+i-1] + f

                call coo_conv (xi2, eta2, u[7], s2, c2, rac, aa, dd)
	     
		call fprintf (ofd,
		    "%6.1f %6.1f %12.2h %12.2h\n")
		    call pargd (Memd[x2+i-1])
		    call pargd (Memd[y2+i-1])
		    call pargd (RADTODEG (aa) / 15)
		    call pargd (RADTODEG (dd))
	    }
	}

	# Free memory
	call mfree (ra,  TY_DOUBLE)
	call mfree (dec, TY_DOUBLE)
	call mfree (x1,  TY_DOUBLE)
	call mfree (y1,  TY_DOUBLE)
	call mfree (xi,  TY_DOUBLE)
	call mfree (eta, TY_DOUBLE)
	call mfree (x2,  TY_DOUBLE)
	call mfree (y2,  TY_DOUBLE)
end


# COO_READ - Read the positions and coordinates of the standards, and the
# coordinates of the stars for which we are finding stars. The format is
# x and y coordinates followed by right ascension and declination. If the
# right ascension and declination are present, the star is a standard star;
# if the celestial coordinates are absent, the star will have its position
# solved for (input star).

procedure coo_read (fd, ra, dec, x1, y1, nstan, x2, y2, nstar)

int	fd			# file descriptor
pointer	ra			# standard stars right ascentioons (rad)
pointer	dec			# standard stars declinations (rad)
pointer	x1			# standard stars x positions (pixels)
pointer	y1			# standard stars y positions (pixels)
int	nstan			# number of standard stars
pointer	x2			# input stars x positions (pixels)
pointer	y2			# input stars y positions (pixels)
int	nstar			# number of input stars

bool	standard		# reading standard stars ?
char	line[SZ_LINE]		# input line
int	maxstan			# current max number of standards
int	maxstar			# current max number of stars
int	i, ip
double	tmpx, tmpy
double	tmpra, tmpdec

int	fscan(), ctod()

begin
	# Initialize counters and flags
	nstan = 0
	nstar = 0
	maxstan = 0
	maxstar = 0
	standard = true

	# Loop over standard stars data
	while (fscan (fd) != EOF) {

	    # Read line
	    call gargstr (line, SZ_LINE)

	    # Check for comment line and skip it
	    if (line[1] == '#')
		next

	    # Parse x, y, ra and dec from the line and
	    # determine if it's a standard star or unknown
	    # star
	    ip = 1
	    if (ctod (line, ip, tmpx) == 0)
		next
	    if (ctod (line, ip, tmpy) == 0)
		next
	    if (ctod (line, ip, tmpra) == 0)
		standard = false
	    if (ctod (line, ip, tmpdec) == 0)
		standard = false

	    # Store star position and allocate more
	    # or reallocate memory for variables if
	    # necessary.
	    if (standard) {

		# Count standard stars
		nstan = nstan + 1

		# Reallocate memory if necessary
	    	if (nstan > maxstan) {
		    if (maxstan == 0) {
			maxstan = STD_INC
			call malloc (ra, maxstan, TY_DOUBLE)
			call malloc (dec, maxstan, TY_DOUBLE)
			call malloc (x1, maxstan, TY_DOUBLE)
			call malloc (y1, maxstan, TY_DOUBLE)
		    } else {
			maxstan = maxstan + STD_INC
			call realloc (ra, maxstan, TY_DOUBLE)
			call realloc (dec, maxstan, TY_DOUBLE)
			call realloc (x1, maxstan, TY_DOUBLE)
			call realloc (y1, maxstan, TY_DOUBLE)
		    }
		}

		# Store data
		Memd[x1+nstan-1] = tmpx
		Memd[y1+nstan-1] = tmpy
		Memd[ra+nstan-1] = tmpra
		Memd[dec+nstan-1] = tmpdec

	    } else {

		# Count stars
		nstar = nstar + 1

		# Reallocate memory if necessary
	    	if (nstar > maxstar) {
		    if (maxstar == 0) {
			maxstar = STAR_INC
			call malloc (x2, maxstar, TY_DOUBLE)
			call malloc (y2, maxstar, TY_DOUBLE)
		    } else {
			maxstar = maxstar + STAR_INC
			call realloc (x2, maxstar, TY_DOUBLE)
			call realloc (y2, maxstar, TY_DOUBLE)
		    }
		}

		# Store data
		Memd[x2+nstar-1] = tmpx
		Memd[y2+nstar-1] = tmpy
	    }
	}

	# Raise error if there are less than three standards
	if (nstan < 3) {

	    # Free memory
	    call mfree (ra, TY_DOUBLE)
	    call mfree (dec, TY_DOUBLE)
	    call mfree (x1, TY_DOUBLE)
	    call mfree (y1, TY_DOUBLE)
	    if (nstar > 1) {
		call mfree (x2, TY_DOUBLE)
		call mfree (y2, TY_DOUBLE)
	    }

	    call error (0, "Must have at least three stars with ra and dec")
	}

	# Convert the right ascention and declination into radians
	# in the arrays RA and DEC respectively. Recall that the 
	# right ascention is stored as hours of time, and the
	# declination as hours of arc.
	do i = 1, nstan {
	    Memd[ra+i-1] = DEGTORAD (Memd[ra+i-1]) * 15
	    Memd[dec+i-1] = DEGTORAD (Memd[dec+i-1])
	}
end


# COO_SL3 - Solves system of 3 linear equations.

procedure coo_sle3 (p1, p2, p3, p4, q1, q2, q3, q4, r1, r2, r3, r4, 
		    alp, bet, gam)

double	p1, p2, p3, p4
double	q1, q2, q3, q4
double	r1, r2, r3, r4
double	alp, bet, gam

double	a1, a2, a3
double	b1, b2, b3
double	det

begin
	a1 = q1 * r2 - q2 * r1
	a2 = q1 * r3 - q3 * r1
	a3 = q1 * r4 - q4 * r1
	b1 = q2 * r3 - q3 * r2
	b2 = q2 * r4 - q4 * r2
	b3 = q3 * r4 - q4 * r3
      
	det = p1 * b1 - p2 * a2 + p3 * a1
	alp = (p4 * b1 - p3 * b2 + p2 * b3) /  det
	bet = (p1 * b3 - p3 * a3 + p4 * a2) / (-det)
	gam = (p1 * b2 - p2 * a3 + p4 * a1) /  det
end


# COO_CONV - Converts X and Y into RA and dec

procedure coo_conv (x, y, u7, s2, c2, rac, ac, dc)

double	x, y
double	u7
double	s2, c2
double	rac
double	ac, dc
double	tda, da, td

begin
	x = x / u7
	y = y / u7
	tda = x / (c2 - y * s2)
	da = atan (tda)
	ac = rac + da
	td = cos (da) * (s2 + y * c2) / (c2 - y * s2)
	dc = atan (td)
end      
