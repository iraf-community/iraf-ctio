# GET_RADII - Calculate minimum, and maximum radius

procedure get_radii (x1, y1, x2, y2, xoffset, yoffset, xc, yc,
		     xshift, yshift, nbands, rmin, rmax)

int	x1, y1, x2, y2			# analysis limits
int	xoffset, yoffset		# subraster extraction offset
real	xc[ARB], yc[ARB]		# center coordinates
real	xshift[ARB], yshift[ARB]	# shifts from center
int	nbands				# number of bands
real	rmin, rmax			# min and max radii

bool	outside
int	i
real	r[4]
real	xx1, xx2, yy1, yy2

begin
	# Calculate radii for each corner
	outside = false
	do i = 1, nbands {

	    # Correct for subraster extraction and shifts
	    xx1 = x1 - xshift[i] + xoffset - 1 - xc[i]
	    xx2 = x2 - xshift[i] + xoffset - 1 - xc[i]
	    yy1 = y1 - yshift[i] + yoffset - 1 - yc[i]
	    yy2 = y2 - yshift[i] + yoffset - 1 - yc[i]

	    # Calculate radii
	    r[1] = sqrt (xx1 ** 2 + yy1 ** 2)
	    r[2] = sqrt (xx1 ** 2 + yy2 ** 2)
	    r[3] = sqrt (xx2 ** 2 + yy1 ** 2)
	    r[4] = sqrt (xx2 ** 2 + yy2 ** 2)

	    # Check if the center is outside of the subraster
	    if ((xc[i] < xx1 && xc[i] < xx2) || (xc[i] > xx1 && xc[i] > xx2) ||
	    	(yc[i] < yy1 && yc[i] < yy2) || (yc[i] > yy1 && yc[i] > yy2))
		outside = true
	}

	# Get the minimum and maximum of the four corners
	call alimr (r, 4, rmin, rmax)

	# If one of the centers is outside of the subraster,
	# keep minimum value. Otherwise set it to zero.
	if (!outside)
	    rmin = 0.0
end
