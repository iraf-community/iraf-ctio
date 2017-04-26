include	<error.h>
include	<mach.h>
include	<pkg/xtanswer.h>

# Codes returned by wrm_gethdr()
define	WRM_OK		1		# ok
define	WRM_WARN	3		# ha != st - ra && st != 0 && ra != 0
define	WRM_ERROR	2		# ha == 0 || st == 0 || ra == 0


# T_WAIRMASS - Copmpute weigthed airmass

procedure t_wairmass ()

char	name[SZ_FNAME]		# input image name
bool	fprecess		# precess by epoch ?
bool	fairmass		# update airmass value ?
bool	fzd			# update zenith distance value ?
bool	fverify			# verify before updating ?
int	inlist			# input images list
int	doair, dozd		# do update ?
int	status			# status from wrm_gethdr()
real	airmass, zd		# airmass and zenith distance values
real	oldairmass, oldzd	# old values
real	darktime, exptime	# dark and exposure time
real	ha, dec			# hour angle and declination
real	latitude		# observatory latitude
pointer	im			# input image descriptor

bool	clgetb()
int	clpopnu(), clgfil()
int	wrm_gethdr()
real	clgetr()
real	imgetr()
pointer	immap()

begin
	# Get input image list
	inlist = clpopnu ("input")

	# Get flags
	fairmass = clgetb ("airmass")
	fzd      = clgetb ("zd")
	#fprecess = clgetb ("precess")
	fverify  = clgetb ("verify")

	# Get observatory latitude
	latitude = clgetr ("latitude")

	# Set interactive update flag
	if (fairmass) {
	    if (fverify)
		doair = YES
	    else
		doair = ALWAYSYES
	} else
	    doair = ALWAYSNO
	if (fzd) {
	    if (fverify)
		dozd = YES
	    else
		dozd = ALWAYSYES
	} else
	    dozd = ALWAYSNO

	# Loop over input images
	while (clgfil (inlist, name, SZ_FNAME) != EOF) {

	    # Try to open image
	    iferr (im = immap (name, READ_WRITE, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Get dark an exposure times and check that they
	    # have the same value. Otherwise issue warning message
	    # and skip image.
	    ifnoerr (darktime = imgetr (im, "DARKTIME")) {
		iferr (exptime = imgetr (im, "EXPTIME")) {
		    iferr (exptime = imgetr (im, "ITIME")) {
		        call erract (EA_WARN)
			call imunmap (im)
		        next
		    }
		}
		if (darktime != exptime) {
		    call eprintf (
		    "Warning: dark and exposure time don't match in [%s]\n")
			call pargstr (name)
		}
	    }

	    # Get header quantities and take different actions according
	    # with the returned status if there is no error.
	    iferr (status = wrm_gethdr (im, ha, dec, exptime)) {
		call erract (EA_WARN)
		call imunmap (im)
		next
	    }
	    switch (status) {
	    case WRM_OK:
		# do nothing
	    case WRM_WARN:
		call eprintf ("Warning: Inconsistent HA, RA, ST in [%s]")
		    call pargstr (name)
		call eprintf (" (RA-ST) assumed\n")
	    case WRM_ERROR:
		call eprintf ("ERROR: Inconsistent HA, RA, ST in [%s]")
		    call pargstr (name)
		call eprintf (" ...skipped\n")
		call imunmap (im)
		next
	    default:
		call error (0, "Unknown wrm_gethdr() code")
	    }

	    # Compute weighted airmass
	    call wairmass (ha, dec, exptime, latitude, airmass, zd)

	    # Get old value of airmass if exists
	    iferr (oldairmass = imgetr (im, "AIRMASS"))
		oldairmass = INDEFR
	    iferr (oldzd = imgetr (im, "ZD"))
		oldzd = INDEFR

	    # Print airmass change
	    call printf ("%s, airmass:         %7.5f -> %7.5f")
	        call pargstr (name)
	        call pargr (oldairmass)
	        call pargr (airmass)
	    if (doair == ALWAYSYES)
		call printf (", updated\n")
	    else if (doair == ALWAYSNO)
	        call printf ("\n")
	    else
	        call xt_answer (", update ?", doair)

	    # Print zenith distance change
	    call printf ("%s, zenith distance: %7.5f -> %7.5f")
	        call pargstr (name)
	        call pargr (oldzd)
	        call pargr (zd)
	    if (dozd == ALWAYSYES)
		call printf (", updated\n")
	    else if (dozd == ALWAYSNO)
	        call printf ("\n")
	    else
	        call xt_answer (", update ?", dozd)

	    # Take action acording to user's answer
	    if (doair == YES || doair == ALWAYSYES)
		call imaddr (im, "AIRMASS", airmass)
	    if (dozd == YES || dozd == ALWAYSYES)
		call imaddr (im, "ZD", zd)

	    # Close input image
	    call imunmap (im)
	}

	# Flush any pending output
	call flush (STDOUT)

	# Close input list
	call clpcls (inlist)
end


# WRM_GETHDR -- Get the hour angle, declination, exposure time, and latitude
# from the image header. Return WRM_NULL if the hour angle is identically
# zero when the right ascension and the sidereal time are zero or not
# present in the header, WRM_NOMATCH if the hour angle in the header is
# not equal to the difference between the right ascension and the sidereal
# time, and WRM_OK otherwise. When WRM_MATCH is returned the hour angle
# is computed from the right ascension and the sidereal time, if they
# are available in the image header.

int procedure wrm_gethdr (im, ha, dec, exptime)

pointer	im			# image descriptor
real	ha			# hour angle (hours)
real	dec			# declination (degrees)
real	exptime			# exposure time (seconds)

int	status
real	ra, st

real	imgetr()
errchk	imgetr()

begin
	# Compute hour based on the header information
	iferr (ha = imgetr (im, "ha")) {
	    ra = imgetr (im, "ra")
	    st = imgetr (im, "st")
	    ha = st - ra
	    if (abs (ra) > EPSILONR && abs (st) > EPSILONR)
	        status = WRM_OK
	    else
		status = WRM_ERROR
	} else {
	    iferr {
		ra = imgetr (im, "ra")
		st = imgetr (im, "st")
	    } then {
		if (abs (ha) < EPSILONR)
		    status = WRM_ERROR
		else
		    status = WRM_OK
	    } else {
		if (abs (ha) < EPSILONR && abs (ra) < EPSILONR &&
		    abs (st) < EPSILONR) {
		    status = WRM_ERROR
		} else if (ha - st + ra > EPSILONR) {
		    if (abs (ra) > EPSILONR && abs (st) > EPSILONR) {
			ha = st - ra
			status = WRM_WARN
		    } else
			status = WRM_ERROR
		} else
		    status = WRM_OK
	    }
	}

	# Get exposure time or integration time
	iferr (exptime = imgetr (im, "exptime"))
	    exptime = imgetr (im, "itime")

	# Get declination
	dec = imgetr (im, "dec")

	# Return status
	return (status)
end
