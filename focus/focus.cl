# FOCUS -- Compute telescope focus.

procedure focus (images, display)

string	images		{ "", prompt = "Images to analize" }
bool	display		{ yes, prompt = "Display image ?" }
imcur	*cursor		{ "imcur", prompt = "Image cursor" }
real	start		{ INDEF, prompt = "Starting focus position" }
real	step		{ INDEF, prompt = "Focus step size" }
real	x
real	y
int	wcs
string	key
struct	*flist1
struct	*flist2

begin
	int	n, npts
	real	a, b, c
	real	xstart, xstep
	real	x1, x2, x3
	real	y1, y2, y3
	real	tx, tx2, tx3, tx4
	real	ty, ty2, ty3
	real	txy, tx2y
	real	delta, focus, factor, aux
	string	imname
	string	xunits, yunits
	string	tmpcur, tmpdata, tmpexam, tmpflds, tmplist, tmpnorm, tmppar

	# Check for tasks defined
	if (!deftask ("display") || !deftask ("fields") || !deftask ("graph")   || !deftask ("imexam") || !deftask ("sections") || !deftask ("imgets")) {
	    beep
	    error (0, "This task needs the 'display', 'fields', 'graph', 'imexam', 'sections', and 'imgets'  tasks defined")
	}

	# Copy start position and step into local variables
	if (start != INDEF && step != INDEF) {
	    xstart = start
	    xstep  = step
	    xunits = " (true)"
	} else {
	    xstart = 0.0
	    xstep  = 1.0
	}

	# Create temporary file names
	tmpcur  = mktemp ("tmpc")
	tmpdata = mktemp ("tmpd")
	tmpexam = mktemp ("tmpe")
	tmpflds = mktemp ("tmpf")
	tmpnorm = mktemp ("tmpn")
	tmplist = mktemp ("tmpl")
	tmppar  = mktemp ("tmpp")

	# Expand image template
	sections (images, option="fullname", > tmplist)

	# Loop over all images
	flist1 = tmplist
	while (fscan (flist1, imname) != EOF) {

	    # Print help for the first time
	    print ("")
	    print ("Press key:")
	    print ("")
	    print ("'a'    to acumulate star positions")
	    print ("'f'    to get the focus for the acumulated positions")
	    print ("'n'    to continue with the next image, if any")
	    print ("'r'    to start over again acumulating points")
	    print ("'q'    to quit")
	    print ("'?'    to get list of possible commands")

	    # Diplay image
	    print ("")
	    print ("Processing image ", imname, "...")
	    if (display) {
		display (imname, 1, erase=yes, border_erase=no, select_frame=yes,
		    repeat=no, fill=no, zscale=yes, contrast=0.25, zrange=yes,
		    nsample_line=5, xcenter=0.5, ycenter=0.5,
		    xsize=1., ysize=1., xmag=1., ymag=1., 
		    order=0, z1=INDEF, z2=INDEF, ztrans="linear", lutfile="")
	    }

	    # Prompt for command
	    print ("Waiting for command...")

	    # Create temporary file for cursor positions
	    if (access (tmpcur))
		delete (tmpcur, verify=no)
	    copy ("dev$null", tmpcur, verbose=no)

	    # Get second per pixel from the image header
	    imgets (imname, "SECPPIX")
	    factor = real (imgets.value)
	    if (factor != 0)
		print ("Arc seconds per pixel for ", imname, " = ", factor)

	    # Loop geting coordinates
	    npts = 0
	    while (fscan (cursor, x, y, wcs, key) != EOF) {

		# Process key
		if (key == "a") {		# acumulate points

		    npts = npts + 1
		    if (npts == 1)
		        print (npts, " point acumulated")
		    else
		        print (npts, " points acumulated")
		    print (x, y, wcs, "a", >> tmpcur)

		} else if (key == "f") {	# determine focus

		    # Print processing message
		    print ("Processing focus..."

		    # Check minimum number of data points
		    if (npts < 3) {
			print ("Not enough star positions acumulated")
			next
		    }

		    # Initialize temporary files
		    if (access (tmpexam))
			delete (tmpexam, verify=no)
		    if (access (tmpflds))
			delete (tmpflds, verify=no)
		    if (access (tmpnorm))
			delete (tmpnorm, verify=no)
		    if (access (tmppar))
			delete (tmppar, verify=no)
		    if (access (tmpdata))
			delete (tmpdata, verify=no)
		    copy ("dev$null", tmpexam, verbose=no)
		    copy ("dev$null", tmpflds, verbose=no)
		    copy ("dev$null", tmpnorm, verbose=no)
		    copy ("dev$null", tmpdata, verbose=no)
		    copy ("dev$null", tmppar, verbose=no)

		    # Examine image
		    imexam (imname, 1, "",
			logfile="", keeplog=no, defkey="a",
			autoredraw=yes, allframes=yes,
			nframes=0, ncstat=5, nlstat=5,
			graphcur="", imagecur=tmpcur, graphics="stdgraph",
			display="display(image='$1',frame=$2)",
			use_display=yes, >> tmpexam)

		    # Extract FWHM from imexam output
		    fields (tmpexam, "11", lines="1-9999",
			quit_if_miss=no, print_file_n=no, >> tmpflds)

		    # Scale points to be in seconds of arc if the
		    # transformation factor is defined. Otherwise
		    # leave them as they are, except that it both
		    # cases INDEF values are skipped, and the point
		    # count decremented.
		    if (factor == 0) {
			factor = 1
			yunits = ""
		    } else
			yunits = " (arcseconds)"
		    flist2 = tmpflds
		    while (fscan (flist2, y) != EOF) {
			if (y == INDEF) {
			    print ("Warning: undefined centroid")
			    npts = npts - 1
			    next
			} else
			    print (y * factor, >> tmpnorm)
		    }

		    # Check minimum number of data points (again)
		    if (npts < 3) {
			print ("Not enough star positions left")
			next
		    }

		    # Get the minimum point and two points around it
		    y1 = 0
		    y2 = 0
		    y3 = 0
		    n = 0
		    flist2 = tmpnorm
		    while (fscan (flist2, y) != EOF) {
			y1 = y2
			y2 = y3
			y3 = y
			n = n + 1
			if (n > 2) {
			    if (y2 < y3)
				break
			}
		    }
		    x1 = (n - 2) * xstep + xstart - xstep
		    x2 = (n - 1) * xstep + xstart - xstep
		    x3 = (n - 0) * xstep + xstart - xstep

		    # Check if a minimum was found
		    if (y1 > y2 && y2 < y3) {

			# Determine parabola parameters
			tx  = x1 + x2 + x3
			ty  = y1 + y2 + y3
			tx2 = x1 ** 2 + x2 ** 2 + x3 ** 2
			tx3 = x1 ** 3 + x2 ** 3 + x3 ** 3
			tx4 = x1 ** 4 + x2 ** 4 + x3 ** 4
			ty2 = y1 ** 2 + y2 ** 2 + y3 ** 2
			ty3 = y1 ** 3 + y2 ** 3 + y3 ** 3
			txy  = x1 * y1 + x2 * y2 + x3 * y3
			tx2y = (x1 ** 2) * y1 + (x2 ** 2) * y2 + (x3 ** 2) * y3
			delta = 3 * (tx2 * tx4 - tx3 * tx3) - tx * (tx * tx4 - tx2 * tx3) + tx2 * (tx * tx3 - tx2 * tx2)
			a = 3 * (tx2 * tx2y - tx3 * txy) - tx * (tx * tx2y - tx2 * txy) + ty * (tx * tx3 - tx2 * tx2)
			b = 3 * (txy * tx4 - tx2y * tx3) - ty * (tx * tx4 - tx2 * tx3) + tx2 * (tx * tx2y - tx2 * txy)
			c = ty * (tx2 * tx4 - tx3 * tx3) - tx * (txy * tx4 - tx2y * tx3) + tx2 * (txy * tx3 - tx2y * tx2)
			a = a / delta
			b = b / delta
			c = c / delta

			# Generate parabola around the point,
			# and get the minimum value for it.
			#for (x = x1; x <= x3 + 0.01; x += (x3 - x1) / 10)
			for (x = xstart; x <= xstart + (npts - 1) * xstep; x += xstep / 10)
			    print (x, a * x * x + b * x + c, >> tmppar)

			# Print minimum and focus
			print ("Minimum at ", x2, ", Focus at ", - b / (2 * a), ", FWHM at minimum is ", y2)

		    } else
			print ("Cannot find minimum")

		    # Generate data points with x axis
		    x = xstart
		    flist2 = tmpnorm
		    while (fscan (flist2, y) != EOF) {
			print (x, y, >> tmpdata)
			x = x + xstep
		    }

		    # Plot points and parabola
		    graph (tmpdata // "," // tmppar,
			wx1=0., wx2=0., wy1=0., wy2=0.,
			axis=1, transpose=no, pointmode=no,
		        marker="box", szmarker=0.005, logx=no, logy=no,
			box=yes, ticklabels=yes,
		        xlabel="position" // xunits, ylabel="FWHM" // yunits,
			title="Data points and parabola around minimum",
			lintran=no, p1=0., p2=0., q1=0., q2=1.,
			vx1=0., vx2=0., vy1=0., vy2=0.,
			majrx=5, minrx=5, majry=5, minry=5,
			append=no, device="stdgraph", round=no, fill=yes)

		    next

		} else if (key == "n") {	# next image
		    print "Next image..."
		    break
		} else if (key == "r") {	# reset acumulation
		    print "Reset acumalated positions..."
		    if (access (tmpcur))
			delete (tmpcur, verify=no)
		    copy ("dev$null", tmpcur, verbose=no)
		    npts = 0
		} else if (key == "q") {	# quit program
		    print "Quit..."
		    break
		} else if (key == "?") {	# print help
		    print ("")
		    print ("Press key:")
		    print ("")
		    print ("'a'    to acumulate star positions")
		    print ("'f'    to get the focus for the acumulated positions")
		    print ("'n'    to continue with the next image, if any")
		    print ("'r'    to start over again acumulating points")
		    print ("'q'    to quit")
		    print ("'?'    to get list of possible commands")
		}

	    } # cursor

	    # Break image loop on quit option
	    if (key == "q")
		    break

	} # images

	# Delete temporary files
	if (access (tmpcur))
	    delete (tmpcur,  verify=no)
	if (access (tmpdata))
	    delete (tmpdata, verify=no)
	if (access (tmpexam))
	    delete (tmpexam, verify=no)
	if (access (tmpflds))
	    delete (tmpflds, verify=no)
	if (access (tmpnorm))
	    delete (tmpnorm, verify=no)
	if (access (tmplist))
	    delete (tmplist, verify=no)
	if (access (tmppar))
	    delete (tmppar,  verify=no)
    end
