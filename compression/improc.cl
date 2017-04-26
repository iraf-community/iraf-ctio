# IMPROC.CL -- Compress or uncompress the pixel file of an IRAF image, and
# update the image header to reflect the change in the pixel file name. The
# pixel file is compressed in place.

procedure improc (images)

string	images		{"", prompt = "Images to compress"}
bool	verbose		{no, prompt = "Verbose operation ?"}
string	operation	{ "compress", min = "|compress|uncompress|", prompt = "Operation"}
struct	*flist

begin
	string	imgs
	string	imname, tmpfile
	string	pixfull, node, pixname
	int	n

	# Get positional arguments
	imgs = images

	# Expand image template
	tmpfile = mktemp ("tmp")
	files (imgs, sort=no, >> tmpfile)

	# Loop over images in the input list
	flist = tmpfile
	while (fscan (flist, imname) != EOF) {

	    # Get pixel file name
	    imgets (imname, "i_pixfile")
	    pixfull = imgets.value

	    # Extract the node name and the pixel file name
	    n = stridx ("$!", imgets.value)
	    if (n  > 0) {
		node    = substr (pixfull, 1, n)
		pixname = substr (pixfull, n + 1, strlen (pixfull))
	    } else {
		node    = ""
		pixname = pixfull
	    }

	    # Check if the pixel file is accessible. This is necessary
	    # because IRAF networking won't be used by the compress task,
	    # since it's declared as foreign.
	    if (!access (pixname)) {
		print ("Pixel file for ", imname, " cannot be accessed")
		next
	    }

	    # Compress the pixel file name, and update image header with the
	    # new pixel file name. It is assumed that a ".Z" is appended to
	    # the compressed pixel file name.
	    if (operation == "compress") {

		# Make sure that the pixel file is not compressed already
		if (stridx ("Z", pixname) == strlen (pixname)) {
		    print ("Image [", imname, "] already compressed")
		    next
		}

		# Compress the pixel file
		if (verbose)
		    _compress ("-v", "-f", pixname)
		else
		    _compress ("-f", pixname)

		# Update image header
		hedit (imname, "i_pixfile",
		       node // pixname // ".Z",
		       add=no, delete=no, verify=no, show=verbose, update=yes)

	    } else {

		# Make sure that the pixel file is not uncompressed already
		if (stridx ("Z", pixname) != strlen (pixname)) {
		    print ("Image [", imname, "] already uncompressed")
		    next
		}

		# Uncompress the pixel file
		if (verbose)
		    _uncompress ("-v", pixname)
		else
		    _uncompress (pixname)

		# Update image header
		hedit (imname, "i_pixfile",
		       node // substr (pixname, 1, strlen (pixname) - 2),
		       add=no, delete=no, verify=no, show=verbose, update=yes)
	    }
	}

	# Delete temporary file
	delete (tmpfile, verify=no)
end
