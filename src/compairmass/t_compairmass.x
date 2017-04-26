# T_COMPAIRMASS -- Compute weighted airmass from data entered by the user.

procedure t_compairmass ()

real	airmass			# air mass
real	dec			# declination (degrees)
real	exptime			# exposure time (seconds)
real	ha			# hour angle (hours)
real	latitude		# observatory latitude (degrees)
real	ra			# rigth ascension (hours)
real	st			# sidereal time (hours)
real	zd			# zenith distance

real	clgetr()

begin
	# Get task parameters
	ha  = clgetr ("ha")
	dec = clgetr ("dec")
	exptime  = clgetr ("exptime")
	latitude = clgetr ("latitude")

	# Compute hour angle if it's undefined
	if (IS_INDEFR (ha)) {
	    ra  = clgetr ("ra")
	    st  = clgetr ("st")
	    if (IS_INDEFR (ra) || IS_INDEFR (st))
		call error (0, "Too many undefined parameters (ha, ra, st)")
	    else
		ha = ra - st
	}

	# Check if there are undefined parameters
	if (IS_INDEFR (dec))
	    call error (0, "Undefined declination")
	if (IS_INDEFR (exptime))
	    call error (0, "Undefined exposure time")
	if (IS_INDEFR (latitude))
	    call error (0, "Undefined latitude")

	# Compute airmass and zenith distance
	call wairmass (ha, dec, exptime, latitude, airmass, zd)

	# Print result
	call printf ("air mass = %g,  zenith distance = %g\n")
	    call pargr (airmass)
	    call pargr (zd)
end
