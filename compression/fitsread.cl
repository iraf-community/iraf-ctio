# FITSREAD.CL -- Make IRAF images from a compressed FITS files.

procedure fitsread (fitsfiles, images)

string	fitsfiles	{"",  prompt = "Input compressed FITS files"}
string	images		{"",  prompt = "Output images"}
string	datatype	{"",  prompt = "IRAF data type"}
real	blank		{0.0, prompt = "Blank value"}
bool	scale		{yes, prompt = "Scale the data ?"}
bool	oldirafname	{no,  prompt = "Use old IRAF name if possible ?"}
bool	verbose		{no,  prompt = "Verbose operation ?"}
bool	fitscomp	{yes, prompt = "Leave the FITS file compressed ?"}
struct	*flist1, *flist2

begin
	string	imgs, fts
	string	tmpim, tmpfits
	string	imname, fitsname

	# Get positional arguments
	fts  = fitsfiles
	imgs = images

	# Expand FITS and image lists
	tmpfits = mktemp ("tmp")
	files (fts, sort=no, >> tmpfits)
	tmpim = mktemp ("tmp")
	files (imgs, sort=no, >> tmpim)

	# Loop over images in the input list
	flist1 = tmpfits
	flist2 = tmpim
	while (fscan (flist1, fitsname) != EOF) {

	    # Get corresponding output image name. Use the old IRAF
	    # name in the image header if the output list is exhausted,
	    # and if the "oldirafname" switch is set. Otherwise break
	    # the loop.
	    if (fscan (flist2, imname) == EOF) {
		if (!oldirafname) {
		    print ("Image list shorter than FITS list")
		    break
		} else
		    imname = ""
	    }

	    # Check for input file and output image existence
	    if (!access (fitsname)) {
		print ("FITS file [", fitsname, "] does not exist (skipped)")
		next
	    }
	    if (access (imname)) {
		print ("Image  [", imname, "] already exists (skipped)")
		next
	    }

	    # Make sure that the FITS file is not uncompressed already
	    if (stridx ("Z", fitsname) != strlen (fitsname)) {
		print ("FITS file [", fitsname, "] already uncompressed")
		next
	    }

	    # Uncompress FITS file
	    if (verbose)
		_uncompress ("-v", fitsname)
	    else
		_uncompress (fitsname)

	    # Take the ".Z" out from the FITS name
	    fitsname = substr (fitsname, 1, strlen (fitsname) - 2)

	    # Read FITS file and write IRAF image
	    rfits (fitsname, "1", imname,
		   make_image=yes, long_header=no, short_header=verbose,
		   datatype=datatype, blank=blank, scale=scale,
		   oldirafname=oldirafname, offset=0)

	    # Recompress the FITS file if necessary
	    if (fitscomp) {
		if (verbose)
		    _compress ("-v", "-f", fitsname)
		else
		    _compress ("-f", fitsname)
	    }
	}

	# Delete temporary files
	delete (tmpfits, verify=no)
	delete (tmpim,   verify=no)
end
