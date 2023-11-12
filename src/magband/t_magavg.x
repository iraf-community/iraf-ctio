include	<error.h>

# Pointer Mem
define	MEMP			Memi

# Maximum number of spectra. This number is used to allocate memory in
# multi-column tables. If more space is needed memory is reallocated
# dynamicaly.
define	MAX_SPECTRA		100

# Maximum number of bandpasses. This number is used t allocate space in
# symbol and sort tables. Sort tables are NOT reallocated dynamically.
define	MAX_BANDS		1000

# Delimiter character used in front of the spectrum name in input files
define	DELIM			"#"

# Number of quantities to read in the spectrum identification ("#", name)
define	SPEC_OK			2

# Number of quantities to read per band (wavelength, width, magnitude/flux)
define	BAND_OK			3

# Bandpass symbol structure
define	BAND_WIDTH		Memr[$1+0]	# width
define	BAND_PMAGFLX		MEMP[$1+1]	# pointer to mag./flux table

# Numeric output format strings
define	FORM_IMAGE		"%6d "		# image sequence number
define	FORM_LAMBDA		"%10.0f "	# wavelength
define	FORM_WIDTH		"%5.0f "	# width
define	FORM_MAGFLX		"%6.3f "	# magnitude/flux
define	FORM_COUNTER		"%4d "		# counter

# Title strings
#				"1234567890 12345 "
define	TITLE_1			"# Wavelen. Width "
#				"123456 123456 123456 1234 1234"
define	TITLE_2			"  Mean  Sigma  Error Npts Nrej"


# T_MAGAVG -- Compute the mean and standard deviation of magitudes/fluxes

procedure t_magavg ()

char	input[SZ_FNAME]			# input file name
char	output[SZ_FNAME]		# output file name
int	inlist				# input file list
int	ifd, ofd			# file descriptors
int	niter				# number of rejection iterations
int	nspec				# number of spectra
int	ns
real	low, high			# rejection limits
pointer	stp				# symbol table pointer

include	"magavg.com"

int	clgeti()
int	clpopnu(), clgfil()
int	open()
int	mav_read()
real	clgetr()
pointer	stopen()
pointer	srt_init()
int	mav_compare()

begin
	# Get parameters
	inlist = clpopnu ("input")
	call clgstr ("output", output, SZ_FNAME)
	low = clgetr ("low")
	high = clgetr ("high")
	niter = clgeti ("niter")

	# Open output file
	ofd = open (output, NEW_FILE, TEXT_FILE)

	# Initialize symbol table. This table will be keyed by the
	# bandpass wavelength, and will contain each one of the
	# magnitudes/fluxes for all the spectra.
	stp = stopen ("magflx", MAX_BANDS, 2 * MAX_BANDS, 10 * MAX_BANDS)

	# Initialize sort table. This table will be used to store and
	# sort the bandpass wavelengths.
	sd = srt_init (MAX_BANDS)

	# Clear spectrum counter
	nspec = 0

	# Loop over all files in input list.
	while (clgfil (inlist, input, SZ_FNAME) != EOF) {

	    # Open input file
	    iferr (ifd = open (input, READ_ONLY, TEXT_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Read file data.
	    ns = mav_read (ifd, input, nspec, stp, sd)
	    if (ns == 0) {
		call eprintf ("Warning: No data in file %s\n")
		    call pargstr (input)
	    } else
		nspec = nspec + ns

	    # Close input file
	    call close (ifd)
	}

	# Sort data in the table, and process output if at least
	# one file was present in the input list.
	if (nspec > 0) {
	    call srt_sort   (sd, mav_compare)
	    call mav_write (ofd, stp, sd, nspec, low, high, niter)
	}

	# Free symbol and sort tables
	call stclose (stp)
	call srt_free (sd)

	# Close input file list and output file
	call clpcls (inlist)
	call close  (ofd)
end


# MAV_READ -- Read spectrum data into memory. The input file MUST be a
# MAGBAND output file in long format. Otherwise, this procedure won't read
# any data. It returns the number of spectra read.

int procedure mav_read (fd, fname, nspec, stp, sd)

int	fd			# input file descriptor
char	fname[ARB]		# input file name
int	nspec			# current number of spectra
pointer	stp			# symbol table pointer
pointer	sd			# sort table pointer

int	ns			# counter of spectra in current file
pointer	delim, name
pointer	sp

bool	streq()
int	fscan(), nscan()
int	mav_rdata()

begin
#call eprintf ("mav_read: fd=%d, fname=%s, nspec=%d, stp=%d, sd=%d\n")
#call pargi (fd)
#call pargstr (fname)
#call pargi (nspec)
#call pargi (stp)
#call pargi (sd)

	# Allocate string space
	call smark (sp)
	call salloc (delim, SZ_LINE, TY_CHAR + 1)
	call salloc (name,  SZ_LINE, TY_CHAR + 1)

	# Clear counter of spectra in the current file
	ns = 0

	# Read file lines until a delimiter character is found followed
	# by the spectrum name. If this is the case then read data from
	# the next lines.
	while (fscan (fd) != EOF) {

	    # Read delimiter character and spectrum name
	    call gargwrd (Memc[delim], SZ_LINE)
	    call gargwrd (Memc[name], SZ_LINE)

	    # Read new data from the file if the line contains the
	    # delimiter character followed by the spectrum name.
	    # Count spectra only if more than one bandpass was read.
	    if (streq (Memc[delim], DELIM) && nscan () == SPEC_OK) {
		if (mav_rdata (fd, fname, nspec + ns, stp, sd) == 0) {
		    call eprintf ("Warning: No bandpasses found in %s")
			call pargstr (fname)
		} else
		    ns = ns + 1
	    }
	}

	# Free string space
	call sfree (sp)

	# Return number of spectra read
	return (ns)
end


# MAV_RDATA -- Read bandpass data (wavelength, magnitude or flux, width)
# from the input file, and put them into a multicolumn table. The end of
# the data for a single spectrum is flagged by a blank line. The latter is
# true for the long output format of MAGBAND. It returns the number of
# bandpasses read.

int procedure mav_rdata (fd, fname, nspec, stp, sd)

int	fd			# input file descriptor
char	fname[ARB]		# input file name
int	nspec			# current number of spectra
pointer	stp			# symbol table pointer
pointer	sd			# sort table pointer


int	nbands
real	wave, magflx, width
pointer	sp, key, sym

int	fscan(), nscan()
pointer	stenter(), stfind()
pointer	srt_put()

begin
#call eprintf ("mav_rdata: fd=%d, fname=%s, nspec=%d, stp=%d, sd=%d\n")
#call pargi (fd)
#call pargstr (fname)
#call pargi (nspec)
#call pargi (stp)
#call pargi (sd)

	# Allocate string space
	call smark (sp)
	call salloc (key, SZ_LINE, TY_CHAR)

	# Clear band counter
	nbands = 0

	# Read lines from file
	while (fscan (fd) != EOF) {

	    # Read data values
	    call gargr (wave)
	    call gargr (magflx)
	    call gargr (width)

	    # Break the loop if no values were read. This condition
	    # flags the end of the data for a single spectrum, since
	    # there should be a blank line at the end of the data.
	    if (nscan () != BAND_OK)
		break

	    # Enter the bandpass data into the symbol table and to the
	    # sort table if it was not already in the symbol table.
	    # Otherwise enter the magnitude/flux for the bandpass in the
	    # symbol table only.
	    call sprintf (Memc[key], SZ_LINE, "%g")
		call pargr (wave)
	    sym = stfind (stp, Memc[key])
	    if (sym == NULL) {

		# Enter bandpass data into symbol table. Initialize
		# all magnitudes/fluxes to INDEF.
		sym = stenter (stp, Memc[key], 1)
		BAND_WIDTH (sym) = width
		call mct_alloc  (BAND_PMAGFLX (sym), MAX_SPECTRA, 1, TY_REAL)
		call mct_clearr (BAND_PMAGFLX (sym), INDEFR)
		call mct_putr   (BAND_PMAGFLX (sym), nspec + 1, 1, magflx)

		# Enter wavelength into sort table
		Memr[srt_put (sd, 1)] = wave

	    } else {

		# Check if the band width is the same as the one entered
		# into the symbol table before. Enter the magnitude/flux
		# into the symbol structure if it's the same.
		if (BAND_WIDTH (sym) != width) {
		    call eprintf (
			"Warning: Inconsistent width for band %g in file %s")
			call pargr (width)
			call pargstr (fname)
		    next
		} else
	    	    call mct_putr (BAND_PMAGFLX (sym), nspec + 1, 1, magflx)
	    }

	    # Count actual number of bandpasses read
	    nbands = nbands + 1
	}

	# Free memory
	call sfree (sp)

	# Return number of bandpasses read
	return (nbands)
end


# MAV_WRITE -- Compute the mean and standard deviation of magnitudes for
# all bandpasses, and write them to the output file along with the individual
# magnitudes, bandpass wavelenth, bandpass with, number of points, and
# number of points rejected.

procedure mav_write (fd, stp, sd, nspec, low, high, niter)

int	fd			# output file descriptor
pointer	stp			# symbol table pointer
pointer	sd			# sort table pointer
int	nspec			# total number of spectra
real	low, high		# rejection limits
int	niter			# number of rejection iterations

int	ns
int	ndspec, nbands, npts
real	wave, mean, sigma
pointer	sp, key, sym, ptr, values, defval

int	srt_nput()
int	mav_average()
pointer	stfind()
pointer	srt_get()
pointer	mct_getbuf()

begin
#call eprintf ("fd=%d, stp=%d, sd=%d, nspec=%d, low=%g, high=%g, niter=%d\n")
#call pargi (fd)
#call pargi (stp)
#call pargi (sd)
#call pargi (nspec)
#call pargr (low)
#call pargr (high)
#call pargi (niter)

	# Get the number of spectra (magnitudes/fluxes) in the band
	# table, and the number of bands in the sort table. Return
	# either if there are no spectra or no bands.
	nbands = srt_nput (sd)
	if (nbands == 0)
	    return

	# Allocate memory
	call smark (sp)
	call salloc (key,  SZ_LINE, TY_CHAR)
	call salloc (defval, nspec, TY_REAL)

	# Write output title
	call fprintf (fd, "\n\n")
	call fprintf (fd, TITLE_1)
	do ns = 1, nspec {
	    call fprintf (fd, FORM_IMAGE)
		call pargi (ns)
	}
	call fprintf (fd, TITLE_2)
	call fprintf (fd, "\n")

	# Iterate over all bandpasses
	call srt_head (sd)
	repeat {

	    # Get next wavelenth from the sort table, and look for it
	    # in the symbol table. Break the loop if there are no more
	    # wavelengths left. Abort the program if the wavelentgh is
	    # not found in the symbol table, because the only way that
	    # this can happend is that something got corrupted.
	    ptr = srt_get (sd)
	    if (ptr != NULL) {
		wave = Memr[ptr]
		call sprintf (Memc[key], SZ_LINE, "%g")
		    call pargr (wave)
		sym = stfind (stp, Memc[key])
		if (sym == NULL)
		    call error (0,"mav_write: Null symbol pointer")
	    } else
		break

	    # Get pointer to data values
	    values = mct_getbuf (BAND_PMAGFLX (sym))

	    # Remove undefined data for bandpass. Undefined data might
	    # come from magnitudes of zero flux bands, or from inexistent 
	    # data for in some spectra for that band.
	    call mav_indef (Memr[values], nspec, Memr[defval], ndspec)

	    # Average bandpasses values for all spectra
	    npts = mav_average (Memr[defval], ndspec, low, high, niter,
				 mean, sigma)
	    # Write output line
	    call fprintf (fd, FORM_LAMBDA)
		call pargr (wave)
	    call fprintf (fd, FORM_WIDTH)
		call pargr (BAND_WIDTH (sym))
	    do ns = 1, nspec {
		call fprintf (fd, FORM_MAGFLX)
		    call pargr (Memr[values + ns - 1])
	    }
	    call fprintf (fd, FORM_MAGFLX)
		call pargr (mean)
	    call fprintf (fd, FORM_MAGFLX)
		call pargr (sigma)
	    call fprintf (fd, FORM_MAGFLX)
		if (IS_INDEFR (sigma) || npts == 0)
		    call pargr (INDEFR)
		else
		    call pargr (sigma / sqrt (real (npts)))
	    call fprintf (fd, FORM_COUNTER)
		call pargi (ndspec)
	    call fprintf (fd, FORM_COUNTER)
		call pargi (ndspec - npts)
	    call fprintf (fd, "\n")
	}

	# Free memory
	call sfree (sp)
end


# MAV_INDEF -- Remove all undefined data from a bandpass.

procedure mav_indef (ivec, inpts, ovec, onpts)

real	ivec[inpts]			# input vector with data points
int	inpts				# number of points in input vector
real	ovec[ARB]			# output vector with data points
int	onpts				# number of points in output vector

int	ip

begin
	# Loop over all points in input vector, copying only
	# defined points to the output vector
	onpts = 0
	do ip = 1, inpts {
	    if (!IS_INDEFR (ivec[ip])) {
		onpts = onpts + 1
		ovec[onpts] = ivec[ip]
	    }
	}
end


# MAV_AVERAGE -- Average data points in a sample. It returns the actual
# number of points used, i.e. the total number of points minus the number
# of rejected points.

int procedure mav_average (vector, npts, low, high, niter, mean, sigma)

real	vector[npts]			# vector with data points
int	npts				# number of points in vector
real	low, high			# rejection limits
int	niter				# number of rejection iterations
real	mean				# vector average (output)
real	sigma				# vector sigma (output)

int	i, norig, nsample
double	dmean, dsigma, lo_cut, hi_cut
pointer	sp, dvec

int	awvgd()

begin
#call eprintf ("mav_average begin: npts=%d, low=%g, high=%g, niter=%d\n")
#call pargi (npts)
#call pargr (low)
#call pargr (high)
#call pargi (niter)

	# Allocate space for temporary double precission vector.
	# This is necessary since it was found that the double
	# precission version of awvg() is needed in order to
	# avoid precission problems.
	call smark (sp)
	call salloc (dvec, npts, TY_DOUBLE)
	call achtrd (vector, Memd[dvec], npts)

	# Compute the average at least one time with no rejection
	norig = awvgd (Memd[dvec], npts, dmean, dsigma, double (0), double (0))

	# Assign the mean and sigma parameters and return, if the
	# number of rejection iterations is less than one, or if
	# the computed sigma is undefined or identicaly zero.
	if (niter < 1 || IS_INDEFD (dsigma) || dsigma == 0.0) {
	    mean  = real (dmean)
	    sigma = real (dsigma)
	    return (norig)
	}

	# Loop rejecting points
	do i = 1, niter {

	    # Compute rejection limits
	    lo_cut = dmean - dsigma * abs (low)
	    hi_cut = dmean + dsigma * abs (high)

	    # Compute new average and sigma
	    nsample = awvgd (Memd[dvec], npts, dmean, dsigma, lo_cut, hi_cut)

	    # Stop rejecting points if there are no rejected points in
	    # this iteration, or if the sigma of the sample is undefined.
	    # Otherwise update the number of points for the next iteration.
	    if (norig == nsample || IS_INDEFD (dsigma))
		break
	    else
		norig = nsample
	}

	# Assign the mean and sigma parameters
	mean  = real (dmean)
	sigma = real (dsigma)

	# Free memory
	call sfree (sp)

	# Return number of points in the sample
	return (nsample)
end


# MAV_COMPARE -- User supplied comparison function required for the sort
# algorithm. It conforms to the srt_sort() conventions.

int procedure mav_compare (index1, index2)

int	index1, index2

pointer	ptr1, ptr2

include	"magavg.com"

pointer	srt_ptr()

begin
	# Get pointers to data
	ptr1 = srt_ptr (sd, index1)
	ptr2 = srt_ptr (sd, index2)

	# Compare
	if (Memr[ptr1] < Memr[ptr2])
	    return (-1)
	else if (Memr[ptr1] > Memr[ptr2])
	    return (1)
	else
	    return (0)
end
