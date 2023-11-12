# FIXTAIL -- Fix the last image lines or columns by either replacing them
# with, or replacing them by the first image lines or columns.

procedure fixtail (inlist, outlist)

string	inlist		{ "",  prompt = "List of images to fix" }
string	outlist		{ "",  prompt = "List of fixed output images" }
int	offset		{ 15,  prompt = "Offset correction" }
string	axis		{ "lines", min="|lines|columns|", prompt = "Line or column offset ?" }
bool	append		{ no,  prompt = "Append offset ?" }

struct	*fdin
struct	*fdout

begin
	string	inlst, outlst
	string	src, dst, all
	string	inim, outim
	string	tmpin, tmpout
	int	offst, ncols, nlines

	# Check for definded tasks
	if (!deftask ("imgets"))
	    print ("This tasks needs `imgets` defined")

	# Get positional parameters
	inlst  = inlist
	outlst = outlist
	offst  = offset

	# Expand list of input and output images
	tmpin  = mktemp ("uparm$tmp")
	files (inlst, sort=no, >> tmpin)
	fdin = tmpin
	tmpout = mktemp ("uparm$tmp")
	files (outlst, sort=no, >> tmpout)
	fdout = tmpout

	# Loop over images in lists
	while ((fscan (fdin, inim) != EOF) && (fscan (fdout, outim) != EOF)) {

	    # Get input image number of lines and columns
	    imgets (inim, "i_naxis1")
	    ncols = int (imgets.value)
	    imgets (inim, "i_naxis2")
	    nlines = int (imgets.value)

	    # Check offset against input image dimension
	    if (axis == "columns") {
		if (offst > ncols) {
		    print (inim,
			   ": offset cannot exceed number of image columns")
		    next
		}
	    } else {
		if (offst > nlines) {
		    print (inim,
			   ": offset cannot exceed number of image lines")
		    next
		}
	    }

	    # Build section strings
	    if (append) {
		if (axis == "columns") {
		    src = "[1:" // str (offst) //  ",*]"
		    dst = "["   // str (ncols + 1) //  ":" //
			  str (ncols + offst) // ",*]"
		    imcreate (outim, 2, (ncols + offst), nlines,
			      header="copy", reference=inim,
			      pixtype="reference")
		} else {
		    src = "[*," // "1:" // str (offst) //  "]"
		    dst = "[*," // str (nlines + 1) //  ":" //
			  str (nlines + offst) // "]"
		    imcreate (outim, 2, ncols, (nlines + offst),
			      header="copy", reference=inim,
			      pixtype="reference")
		}
		all = "[1:" // str (ncols) // ",1:" // str (nlines) // "]"

		imcopy (inim // all, outim // all, verbose=no)
		imcopy (inim // src, outim // dst, verbose=no)
	    } else {
		if (axis == "columns") {
		    src = "[1:" // str (offst) //  ",*]"
		    dst = "["   // str (ncols - offst + 1) //  ":" //
			  str (nlines) // ",*]"
		} else {
		    src = "[*," // "1:" // str (offst) //  "]"
		    dst = "[*," // str (nlines - offst + 1) //  ":" //
			  str (nlines) // "]"
		}

		imcopy (inim, outim, verbose=no)
		imcopy (inim // src, outim // dst, verbose=no)
	    }
	}
	
	# Delete temporary files
	delete (tmpin,  verify=no)
	delete (tmpout, verify=no)
end
