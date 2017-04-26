include	<math.h>

# IMDATA
#
# Airmass formulation from Allen "Astrophysical Quantities" 1973 p.125,133
# and John Ball's book on Algorithms for the HP-45.

procedure imdata (ra, dec, latitude, st, airmass, ha, zd)

double	ra, dec			# ra and dec (degress)
double	latitude		# observatory latitude (degrees)
double	st			# sidereal time (decimal hours)
double	airmass			# air mass (output)
double	ha			# hour angle (output)
double	zd			# zenith angle (output)

double	coszd, scale, x, decrad, latrad, zdrad, hrad
data	scale/750.0/		# Atmospheric scale height approx

begin

	# Compute hour angle
	ha = st - ra

	# Compute zenith distance
	hrad = DEGTORAD (ha) * 15
	decrad = DEGTORAD (dec)
	latrad = DEGTORAD (latitude)
	coszd = sin (latrad) * sin (decrad) +
		cos (latrad) * cos (decrad) * cos (hrad)
	zd = RADTODEG (acos (coszd))

	# Compute airmass from zenith distance.
	zdrad = DEGTORAD (zd)
	x = scale * cos (zdrad)
	airmass = sqrt (x ** 2 + 2 * scale + 1) - x
end
