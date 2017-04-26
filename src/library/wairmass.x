include	<math.h>

# Length of the time intervals (in seconds) for dividing the total
# exposure time.
define	INTERVAL	300	


# IM_WAIRMASS - Compute the weigthted airmass for a given image. The
# latitude is given as a parameter since it's not recorded in the header
# for most images. This procedure assumes that the hour angle and sidereal
# time were recorded in the header at the begining of the observation. No
# check is made for dark time. The airmass and zenith distance are returned
# as output from the procedure.

real procedure im_wairmass (im, latitude, precess, airmass, zd)

pointer	im			# image descriptor
real	latitude		# observatory latitude (degrees)
bool	precess			# precess coordinates by epoch ?
real	airmass			# airmass value
real	zd			# zenith distance value (degress)

real	exptime			# exposure time
real	ha, ra, dec, st

real	imgetr()
errchk	imgetr()

begin
	# Compute hour angle if not defined
	iferr (ha = imgetr (im, "ha")) {
	    st = imgetr (im, "st")
	    ra = imgetr (im, "ra")
	    ha = st - ra
	}

	# Get exposure time or integration time
	iferr (exptime = imgetr (im, "exptime"))
	    exptime = imgetr (im, "itime")

	# Get declination
	dec = imgetr (im, "dec")

	# Precess coordinates if necessary
	if (precess) {
	    #time = clktime (0)
	    #call bktime (time, ostruct)
	    #call ast_date_to_epoch (year, month, day, ut, epoch)
	    #call ast_precess (ra1, dec1, epoch1, ra2, dec2, epoch2)
	}

	# Compute airmass and zenith distance values
	call wairmass (ha, dec, exptime, latitude, airmass, zd)
end


# Atmospheric scale height approximation
define	SCALE	750.0

# WAIRMASS - Compute weighted airmass, and zenith distance, by dividing
# the exposure time into intervals and averaging the airmass for each interval.
# This procedure assumes that the hour angle or the sidereal time corresponds
# to the begining of the observation.
#
# Airmass formulation from Allen "Astrophysical Quantities" 1973 p.125,133
# and John Ball's book on Algorithms for the HP-45.

procedure wairmass (ha, dec, exptime, latitude, airmass, zd)

real	ha			# hour angle (hours)
real	dec			# declination (degrees)
real	exptime			# exposure time (seconds)
real	latitude		# observatory latitude (degrees)
real	airmass			# airmass value (output)
real	zd			# zenith distance value (output)

int	nint			# number of intervals
int	i
real	coszd			# cosine of zenith distance for one interval
real	harad, decrad, latrad	# in radians
real	airval, zdval		# values for one interval
real	t0, t, delta
real	x
real	temp1, temp2
double	airsum, zdsum		# sums for all intervals


begin
	# Convert to radians
	harad = DEGTORAD (ha) * 15
	decrad = DEGTORAD (dec)
	latrad = DEGTORAD (latitude)

	# Compute constant for zenith distance
	# calculations
	temp1 = sin (latrad) * sin (decrad)
	temp2 = cos (latrad) * cos (decrad)

	# Compute number of intervals to divide the
	# exposure time
	nint = int (exptime / INTERVAL + 0.99999)
	if (nint < 1)
	    nint = 1

	# Compute time interval and initial time for
	# airmass evaluation
	delta = exptime / nint
	t0 = delta / 2

	# Compute the weighted airmass
	airsum = 0.0
	zdsum = 0.0
	do i = 1, nint {
	    t = (t0 + (i-1) * delta) / 3600
	    coszd = temp1 + temp2 * cos (harad + DEGTORAD (t) * 15)
	    x = SCALE * coszd
	    airval = sqrt (x ** 2 + 2 * SCALE + 1) - x
	    zdval = acos (coszd)
	    airsum = airsum + airval
	    zdsum = zdsum + zdval
	}

	# Compute final values
	airmass = airsum / nint
	zd = RADTODEG (zdsum / nint)
end
