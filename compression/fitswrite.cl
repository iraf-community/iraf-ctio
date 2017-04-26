# FITSWRITE.CL -- Make compressed FITS files from an IRAF images.

procedure fitswrite (images, fitsfiles, bscale, bzero)

string	images		{"",  prompt = "Input images"}
string	fitsfiles	{"",  prompt = "Output compressed FITS files"}
real	bscale		{1.0, prompt = "FITS bscale"}
real	bzero		{0.0, prompt = "FITS bzero"}
int	bitpix		{0,   prompt = "FITS bits per pixel"}
bool	scale		{yes, prompt = "Scale data ?"}
bool	autoscale	{yes, prompt = "Auto scaling ?"}
bool	verbose		{no,  prompt = "Verbose operation ?"}
struct	*flist1, *flist2

begin
	string	imgs, fts
	string	tmpim, tmpfits
	string	imname, fitsname

	# Get input and output lists
	imgs = images
	fts  = fitsfiles

	# Expand image and FITS lists
	tmpim = mktemp ("tmp")
	files (imgs, sort=no, >> tmpim)
	tmpfits = mktemp ("tmp")
	files (fts, sort=no, >> tmpfits)

	# Loop over images in the input list
	flist1 = tmpim
	flist2 = tmpfits
	while (fscan (flist1, imname) != EOF) {
	
	    # Get corresponding output FITS file name
	    if (fscan (flist2, fitsname) == EOF) {
		print ("FITS list shorter than image list")
		break
	    }
 
	    # Check for input file and output image existence
	    if (!access (imname) && !access (imname // ".imh")) {
		print ("Image  [", imname, "] does not exist (skipped)")
		next
	    }
	    if (access (fitsname)) {
		print ("FITS file [", fistname, "] already exists (skipped)")
		next
	    }
	    if (access (fitsname // ".Z")) {
		print ("FITS file [", fistname // ".Z",
		       " already exists (skipped)")
		next
	    }

	    # Make temporary FITS file
	    wfits (imname, fitsname, yes, bscale, bzero,
		   make_image=yes,long_header=no, short_header=verbose,
		   bitpix=bitpix, blocking_fac=1,
		   scale=scale, autoscale=autoscale)

	    # Compress FITS file
	    if (verbose)
		_compress ("-v", "-f", fitsname)
	    else
		_compress ("-f", fitsname)
	}

	# Delete temporary files
	delete (tmpim,   verify=no)
	delete (tmpfits, verify=no)
end
