# IMEXTRACT.CL -- Extract a list of image sections defined by a list of
# pixel coordinates given in a file. The section to extract is defined
# either by supplying the width and heigth along with the pixel coordinates,
# or by using the default number of lines and columns defined in the task
# parameters.

procedure ezimtool (image, coordinates)

string	image		{ "", prompt = "Image name" }
string	coordinates	{ "", prompt = "Coordinate file name" }
real	width		{ INDEF, min = 1, prompt = "Section width (pixels)" }
real	height		{ INDEF, min = 1, prompt = "Section height (pixels)" }
int	x, y, dx, dy
struct	*flist

begin
	string	imname, coname
	string	output, section, sequence
	string	tmpfile
	int	n, ncoords, nlines
	int	x1, x2, y1, y2
	int	xmax, ymax

	# Check for defined tasks
	if (!deftask ("imcopy") || !deftask ("hselect"))
	    error (0, "This task needs `hselect` and `imcopy` defined")

	# Get task parameters
	imname = image
	coname = coordinates

	# Get rid of ".imh" extension in image name
	n = strlen (imname)
	if (substr (imname, n - 3, n) == ".imh")
	    imname = substr (imname, 1, n - 4)

	# Check file existence
	if (!access (imname // ".imh"))
	    error (0, "Image does not exist")
	if (!access (coname))
	    error (0, "Coordinate file does not exist")

	# Get input image dimensions
	tmpfile = mktemp ("tmp")
	hselect (imname, "i_naxis1,i_naxis2", "yes", > tmpfile)
	flist = tmpfile
	n = fscan (flist, xmax, ymax)
	if (nscan () < 2) {
	    delete (tmpfile, verify=no)
	    error (0, "Input image is one-dimensional")
	}

	# Initializer coordinate and line counter
	ncoords = 0
	nlines  = 0

	# Loop reading file.
	flist = coname
	while (fscan (flist, x, y, dx, dy) != EOF) {

	    # Count lines
	    nlines = nlines + 1

	    # Check number read
	    if (nscan () < 2) {
		print ("Bad format for line", nlines, "...skipped")
		next
	    }
	    if (nscan () < 4) {
		dx = width
		dy = height
	    }

	    # Check for INDEF numbers
	    if (x == INDEF || y == INDEF) {
		print ("Undefined coordinate for line ", nlines, "...skipped")
		next
	    }
	    if (dx == INDEF || dy == INDEF) {
		print ("Undefined size for line ", nlines, "...skipped")
		next
	    }

	    # Count coordinates
	    ncoords = ncoords + 1

	    # Compute section boundaries
	    x1 = int (x - dx / 2)
	    x2 = int (x + dx / 2)
	    y1 = int (y - dy / 2)
	    y2 = int (y + dy / 2)

	    # Check section boundaries
	    if (x1 < 1 || x1 > xmax)
		print ("Lower column out of range for coordinate ", ncoords,
		       "...truncated")
	    if (x2 < 1 || x2 > xmax)
		print ("Upper column out of range for coordinate ", ncoords,
		       "...truncated")
	    if (y1 < 1 || y1 > xmax)
		print ("Lower line out of range for coordinate ", ncoords,
		       "...truncated")
	    if (y2 < 1 || y2 > xmax)
		print ("Upper line out of range for coordinate ", ncoords,
		       "...truncated")

	    # Limit section boundaries
	    x1 = max (1, min (x1, xmax))
	    x2 = max (1, min (x2, xmax))
	    y1 = max (1, min (y1, ymax))
	    y2 = max (1, min (y2, xmax))

	    # Build sequence string that will be appended to
	    # image name to form the output name
	    sequence = str (ncoords)
	    while (strlen (sequence) < 3)
		sequence = "0" // sequence
	    sequence = "." // sequence

	    # Build output image section
	    section = "[" // str (x1) // ":" // str (x2) // "," \
		      // str (y1) // ":" // str (y2) // "]"

	    # Copy image section if output image does not exist
	    output = imname // sequence // ".imh"
	    if (access (output))
		print ("Output image ", output, " already exists...skipped"
	    else
		imcopy (imname // section, output, verbose=yes)
	}

	# Delete temporary file
	delete (tmpfile, verify=no)
end
