# FPSPEC - Take a list of images and plot a single pixel value as a function
# of the image number. The pixel coordinate is read from the standard image
# cursor, or from file. The middle image in the input list is displayed if
# no one is specified.

procedure fpspec (images)

string	images		{ "", prompt = "Input images" }
string	display_image	{ "", prompt = "Image to display" }
imcur	*cursor		{ "", prompt = "Image cursor" }
real	x		{ INDEF }
real	y		{ INDEF }
real	wcs		{ INDEF }
string	key		{ INDEF }
struct	*flist		{ "" }
string	fname		{ "" }

begin
	int	n, num
	string	section			# image section
	string	tmpfile1, tmpfile2	# temporary files

	# Test for packages needed
	if (!defpac ("tv") || !defpac ("plot") || !defpac ("proto")) {
	    beep ()
	    error (0,
	    "This task needs packages 'tv', 'plot', and 'proto' loaded")
	}

	# Expand template and store it into a
	# temporary file
	tmpfile1 = mktemp ("tmp")
	sections (images, option="fullname", > tmpfile1)

	# Test number of images
	if (sections.nimages == 0) {
	    delete (tmpfile1, verify=no)
	    call error (0, "No images specified")
	}

	# Display middle image if none specified
	if (display_image == "") {
	    num = max (sections.nimages / 2, 1)
	    flist = tmpfile1
	    for (n = 1; n <= num; n+=1)
	        if (fscan (flist, fname) == EOF)
		    error (0, "Unexpected end of file")
	} else
	    display (display_image, 1, erase=yes)

	#flist = tmpfile1
	#if (fscan (flist, fname) != EOF)
	    #display (fname, 1, erase=yes)

	# Loop reading cursor coordinates
	while (fscan (cursor, x, y, z, key) != EOF) {

	    # Quit if 'q' was pressed
	    if (key == "q")
		break

	    # Build image section to specify only a single pixel
	    section = "[" // str (int (x)) // ":" // str(int (x)) // "," \ 
			  // str (int (y)) // ":" // str(int (y)) // "]"

	    # Build temporary file name 2
	    tmpfile2 = mktemp ("tmp")

	    # Loop over images storing single pixel
	    # values into a temporary file 2
	    flist = tmpfile1
	    while (fscan (flist, fname) != EOF)
		listpix (fname // section, >> tmpfile2)

	    # Graph second column (pixel values) from
	    # temporary file 2
	    fields (tmpfile2, "2", lines="1-9999",
		    quit_if_miss=no, print_file_n=no) |
		graph (title="x=" // str (int (x)) // ", y=" // str (int (y)))

	    # Delete temporary file 2
	    delete (tmpfile2, verify=no)
	}

	# Delete temporary file 1
	delete (tmpfile1, verify=no)
end
