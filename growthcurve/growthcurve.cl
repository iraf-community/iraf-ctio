# GROWTHCURVE.CL -- Correct magnitudes, coming from APPHOT, using the
# growth curve. The input can be a list of input files, and the output
# is a list of files whose names are built automatically from each input
# file name. The user is able to interactively fit the growth curve,
# or just run it blindly.

procedure growthcurve (files, naps, small, large)

string	files		{ "", prompt = "Input files" }
int	naps		{ 1, min = 1, prompt = "Total number of apertures" }
int	small		{ 1, min = 1, prompt = "Small aperture number" }
int	large		{ 1, min = 1, prompt = "Large aperture number" }
string	function	{ "legendre", prompt = "Type of function to fit" }
int	order		{ 8, min = 1, prompt = "Order of the fit" }
bool	interactive	{ yes, prompt = "Fit interactively ?" }
bool	preserve	{ no,  prompt = "Preserve fit ?" }
struct	*flist

begin
	string	fls
	int	nps, sml, lrg
	int	i, len, nap, id, id1, id2, obj, nobjs
	real	mag, mag1, mag2, merr, x1, x2, diff, sum
	string	inname, outname, fitname, tmpfile0, tmpfile1, tmpfile2

	# Check for defined tasks
	if (!(deftask ("txdump") && deftask ("curfit")))
	    error (0, "This task needs `txdump` and `curfit` defined")

	# Get parameters
	fls = files
	nps  = naps
	if (!interactive) {
	    while (yes) {
		sml = small
		lrg = large
		if (sml >= lrg || lrg > nps)
		    print ("Error: Inconsistent aperture numbers... try again")
		else
		    break
	    }
	}

	# Create temporary files
	tmpfile0 = mktemp ("tmp")
	copy ("dev$null", tmpfile0, verbose=no)
	tmpfile1 = mktemp ("tmp")
	copy ("dev$null", tmpfile1, verbose=no)
	tmpfile2 = mktemp ("tmp")
	copy ("dev$null", tmpfile2, verbose=no)

	# Loop over files
	files (fls, sort=yes, >> tmpfile0)
	flist = tmpfile0
	while (fscan (flist, inname) != EOF) {

	    # Search for a ".mag." in the file name, and replace it by
	    # a ".grw." in the output file, and ".fit." in the file
	    # contaning the fit. Otherwise just append a ".grw", and
	    # a ".fit" to them.
	    i = 1
	    len = strlen (inname)
	    while (i <= len - 4) {
		if (substr (inname, i, i + 4) == ".mag.") {
		    outname = substr (inname, 1, i - 1) // ".grw." //
			      substr (inname, i + 5, len)
		    fitname = substr (inname, 1, i - 1) // ".fit." //
			      substr (inname, i + 5, len)
		    break
		} else
		    i = i + 1
	    }
	    if (i > len - 4) {
		outname = inname // ".grw"
		fitname = inname // ".fit"
	    }

	    # Print file name, if interactive
	    if (interactive)
	        print ("--- Processing file ", inname, ", output to ", outname)

	    # Check for output file existence
	    if (access (outname)) {
		print ("Warning: output file ", outname, " already exists... skipped")
		next
	    }

	    # Extract star id's and magnitudes from the the APPHOT output.
	    delete (tmpfile1, verify=no)
	    copy ("dev$null", tmpfile1, verbose=no)
	    for (nap = 1; nap <= nps; nap += 1) {
		txdump (inname, "id,mag[" // str (nap) // "]",
			"yes", headers=no, parameters=no, >> tmpfile1)
	    }

	    # Count number of objects in APSELECT output
	    nobjs = 0
	    flist = tmpfile1
	    while (fscan (flist, id2, mag2) != EOF) {
		if (nscan () == 2)
		    nobjs = nobjs + 1
		else
		    break
	    }

	    # Print number of objects found, if interactive
	    if (interactive)
	        print ("Number of objects found = ", nobjs)

	    # Extract each object from the APSELECT output, so magnitudes
	    # are grouped by object, with the first object at the beginning.
	    delete (tmpfile2, verify=no)
	    copy ("dev$null", tmpfile2, verbose=no)
	    for (obj = 1; obj <= nobj; obj += 1) {
		match ("^" // str (obj), tmpfile1, stop=no,
		       print_file_names=no, metacharacters=yes, >> tmpfile2)
	    }

	    # Compute magnitude differences
	    id1  = -999
	    mag1 = -999
	    flist = tmpfile2
	    delete (tmpfile1, verify=no)
	    copy ("dev$null", tmpfile1, verbose=no)
	    while (fscan (flist, id2, mag2) != EOF) {

		# Skip incomplete lines
		if (nscan () < 2)
		    next

		# Check if the object has changed, and if so
		# reset the aperture number.
		if (id2 != id1) {
		    id1 = id2
		    nap = 1
		}

		# Print the aperture number and magnitude difference
		# into the temporary file, but only if more than one
		# aperture has been read.
		if (nap > 1)
		    print (nap, (mag2 - mag1), >> tmpfile1)

		# Update magnitude and increment aperture number
		mag1 = mag2
		nap  = nap + 1
	    }

	    # Fit a curve to the differences
	    delete (tmpfile2, verify=no)
	    curfit (tmpfile1, function=function, weighting="uniform",
		    order=order, interactive=interactive, axis=1,
		    listdata=yes, verbose=no, calctype="real",
		    power=no, device="stdgraph", cursor="", > tmpfile2)


	    # Get aperture numbers, if interactive. Otherwise
	    # use values entered at the beginning.
	    if (interactive) {
		while (yes) {
		    sml = small
		    lrg = large
		    if (sml >= lrg || lrg > nps)
			print ("Error: Inconsistent aperture numbers... try again")
		    else
			break
		}
	    }

	    # Read the CURFIT output file adding differences from the
	    # small to the large aperture. Read aperture numbers as
	    # real numbers to deal with eventual decimal points in the
	    # CURFIT output, but take the integral part of aperture
	    # numbers in order to avoid rounding errors in comparisons.
	    x1 = -999.9
	    sum = 0.0
	    flist = tmpfile2
	    while (fscan (flist, x2, diff) != EOF) {
		
		# Check input
		if (nscan () < 2)
		    next

		# Add difference only if the aperture number is in
		# the desired range, and only one time per aperture.
		if (int (x2) > lrg)
		    break
		else if (int (x2) > sml && x2 != x1) {
		    sum = sum + diff
		    x1 = x2
		} else
		    next
	    }

	    # Print magnitude correction, if interactive
	    if (interactive)
		print ("Magnitude correction = ", sum)

	    # Extract star id, magnitude, and magnitude error for
	    # the large aperture.
	    delete (tmpfile1, verify=no)
	    txdump (inname, "id,mag[" // str (sml) // "],merr[" //
		    str (lrg) // "]", "yes",
		    headers=no, parameters=no, >> tmpfile1)

	    # Correct magnitudes
	    flist = tmpfile1
	    copy ("dev$null", outname, verbose=no)
	    while (fscan (flist, id, mag, merr) != EOF) {

		# Check input
		if (nscan () < 3)
		    next

		# Print results to output file
		print (id, mag, (mag + sum), merr, >> outname)
	    }
	}

	# Delete temporary files
	delete (tmpfile1, verify=no)
	if (preserve) {
	    if (access (fitname)) {
		print ("Warning: fit file ", fitname, " already exists... skipped")
	        delete (tmpfile2, verify=no)
	    } else
	        rename (tmpfile2, fitname, field="root")
	} else
	    delete (tmpfile2, verify=no)
        delete (tmpfile0, verify=no)
end
