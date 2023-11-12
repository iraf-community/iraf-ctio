include <math.h>
include <error.h>

# Minimum and maximum values allowed
# for the sidereal time (hours)
define	ST_MIN		0.0
define	ST_MAX		24.0

# Minimum and maximum values allowed
# for the hour angle (hours)
define	HA_MIN		0.0
define	HA_MAX		24.0

# Minimum and maximum values allowed
# for the zenith distance (degrees)
define	ZD_MIN		0.0
define	ZD_MAX		90.0

# Minimum and maximum values allowed
# for the airmass
define	AIR_MIN		1.0
define	AIR_MAX		10.0

# HELIO - Driver procedure for the heljd subroutine.
# Opens a list of images, reads the necessary values from the header
# and call the "heljd" Fortran subroutine. The values of the julian
# date, helicentric juylian date and heliocentric rv correction are
# allways added to the header. The values for the sidereal time, hour
# angle, zenith distance and airmass are added only if they are not
# present or if they have wrong values.

procedure t_helio()

char	images[SZ_FNAME]	# image name list
char	name[SZ_FNAME]		# image name
char	date[SZ_LINE]		# observation date
char	aux[SZ_LINE]
int	len			# list length
int	i, n, ip
int	day, month, year	# day, month and year
double	ut			# universal time (hours)
double	ra, dec			# ra and dec (radians)
double	latitude		# observatory latitude (degrees)
double	longitude		# observatory longitude (degrees)
double	jd			# julian date
double	hjd			# heliocentric julian date
double	st			# local sideral time (radians)
double	ha			# hour angle (radians)
double	zd			# zenith distance (radians)
double	airmass			# air mass
double	hcorr			# heliocentric correction
double	oldst			# old value of st (hours)
double	oldha			# old value of ha (hours)
double	oldzd			# old value of zd (degrees)
double	oldairmass		# old value of air mass
pointer	list			# image names list
pointer	im			# image descriptor

int	fntlenb(), fntgfnb(), ctoi(), strext()
double	clgetd(), imgetd()
pointer	fntopnb(), immap()

begin
	# Get parameters
	call clgstr ("images", images, SZ_FNAME)
	latitude = clgetd ("latitude")
	longitude = clgetd ("longitude")

	# Open the input list
	list = fntopnb (images, YES)
	len = fntlenb (list)

	# Iterate over all images
	do i = 1, len {

	    # Get next image name and open it
	    n = fntgfnb (list, name, SZ_FNAME)
	    iferr (im = immap (name, APPEND, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get right ascention from the header and
	    # convert it into radians
	    iferr (ra = imgetd (im, "RA")) {
		call erract (EA_WARN)
		next
	    }
	    ra = DEGTORAD (ra) * 15

	    # Get declination from the header and
	    # convert it into radians
	    iferr (dec = imgetd (im, "DEC")) {
		call erract (EA_WARN)
		next
	    }
	    dec = DEGTORAD (dec)

	    # Get universal time from the header
	    iferr (ut = imgetd (im, "UT")) {
		call erract (EA_WARN)
		next
	    }

	    # Get date of observation from the header
	    iferr (call imgstr (im, "DATE-OBS", date, SZ_LINE)) {
		call erract (EA_WARN)
		next
	    }

	    # Extract day, month and year from date
	    n = 1
	    ip = 1
	    if (strext (date, ip, "/", YES, aux, SZ_LINE) == 0) {
		call eprintf ("Warning: cannot obtain day from date (%s)\n")
		    call pargstr (date)
		next
	    } else if (ctoi (aux, n, day) == 0) {
		call eprintf ("Warning: cannot convert day (%s)\n")
		    call pargstr (aux)
		next
	    }

	    n = 1
	    if (strext (date, ip, "/", YES, aux, SZ_LINE) == 0) {
		call eprintf ("Warning: cannot obtain month from date (%s)\n")
		    call pargstr (date)
		next
	    } else if (ctoi (aux, n, month) == 0) {
		call eprintf ("Warning: cannot convert month (%s)\n")
		    call pargstr (aux)
		next
	    }

	    n = 1
	    if (strext (date, ip, "/", YES, aux, SZ_LINE) == 0) {
		call eprintf ("Warning: cannot obtain year from date (%s)\n")
		    call pargstr (date)
		next
	    } else if (ctoi (aux, n, year) == 0) {
		call eprintf ("Warning: cannot convert year from string (%s)\n")
		    call pargstr (aux)
		next
	    }
	    year = year + 1900

	    # Call the heliocentric (black box) routine
	    call heljd (ra, dec, month, double(day), double(year), ut, latitude,
			longitude, jd, hjd, st, ha, zd, airmass, hcorr)

	    # Convert units for output
	    st = RADTODEG (st) / 15
	    ha = RADTODEG (ha) / 15
	    zd = RADTODEG (zd)

	    # Put the sidereal time, hour angle, zenith distance
	    # and airmass in the header if they don't are present
	    # or if the have illegal values

	    iferr (oldst = imgetd (im, "ST")) {
		call imaddd (im, "ST", st)
	    } else if (oldst < ST_MIN || oldst > ST_MAX) {
		call imputd (im, "ST", st)
	    }

	    iferr (oldha = imgetd (im, "HA")) {
		call imaddd (im, "HA", ha)
	    } else if (oldha < HA_MIN || oldha > HA_MAX) {
		call imputd (im, "HA", ha)
	    }

	    iferr (oldzd = imgetd (im, "ZD")) {
		call imaddd (im, "ZD", zd)
	    } else if (oldzd < ZD_MIN || oldzd > ZD_MAX) {
		call imputd (im, "ZD", zd)
	    }

	    iferr (oldairmass = imgetd (im, "AIRMASS")) {
		call imaddd (im, "AIRMASS", airmass)
	    } else if (oldairmass < AIR_MIN || oldairmass > AIR_MAX) {
		call imputd (im, "AIRMASS", airmass)
	    }

	    # Put julian day, heliocentric julian day and
	    # heliocentric velocity correction in the header
	    call imaddd (im, "JD", jd)
	    call imaddd (im, "HJD", hjd)
	    call imaddd (im, "HCORR", hcorr)

	    # Print output (test only)
	    call printf ("image=%s\tjd=%g\thjd=%g\thcorr=%g\n")
		call pargstr (name)
		call pargd (jd)
		call pargd (hjd)
		call pargd (hcorr)

	    # Close image
	    call imunmap (im)
	}
end
