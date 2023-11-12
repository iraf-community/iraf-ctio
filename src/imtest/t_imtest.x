include	<diropen.h>
include	<error.h>


# T_IMTEST -- Traverse the header directory looking for image headers,
# and the pixel directory looking for pixel files that doesn't match
# the list of headers. The output of the program are CL statements to
# delete the image headers and pixel files, i.e. a CL script.

procedure t_imtest ()

bool	verbose			# verbose output ?
bool	verify			# verify before deleting files ?
bool	ignore			# ignore node name ?
int	hdrlist			# headers directory list
int	pixlist			# pixels directory list
pointer	hdrname			# current header directory mame
pointer	pixname			# current pixel directory mame
pointer	pixtable		# pixels symbol table
pointer	sp

bool	clgetb()
int	clpopnu(), clgfil()
pointer	stopen()

begin
	# Allocate space for strings
	call smark (sp)
	call salloc (hdrname, SZ_FNAME, TY_CHAR)
	call salloc (pixname, SZ_FNAME, TY_CHAR)

	# Get parameters
	hdrlist = clpopnu ("imhdir")
	pixlist = clpopnu ("pixdir")
	verbose = clgetb ("verbose")
	verify = clgetb ("verify")
	ignore = clgetb ("ignore")

	# Open pixels table
	pixtable = stopen ("pixels", 10, 100, 100 * SZ_FNAME)

	# Loop over list of header directories
	while (clgfil (hdrlist, Memc[hdrname], SZ_FNAME) != EOF) {
	    call imts_headers (Memc[hdrname], pixtable,
			       verbose, verify, ignore)
	}

	# Loop over list of pixel directories
	while (clgfil (pixlist, Memc[pixname], SZ_FNAME) != EOF) {
	    call imts_pixels (Memc[pixname], pixtable,
			      verbose, verify, ignore)
	}

	# Close pixel table
	call stclose (pixtable)

	# Close lists
	call clpcls (hdrlist)
	call clpcls (pixlist)

	# Free memory
	call sfree (sp)
end


# IMTS_HEADERS -- Traverse a header files directory looking for images
# without pixel file. All the pixel file names found are stored in a
# symbol table for later use by the imts_pixels() procedure.

procedure imts_headers (hdrname, pixtable, verbose, verify, ignore)

char	hdrname[ARB]		# directory name
pointer	pixtable		# pixels table
bool	verbose			# verbose output ?
bool	verify			# delete verification ?
bool	ignore			# ignore node name ?

int	offset			# node string offset
int	n
pointer	filename		# pointer to next file name
pointer	pathname		# pointer to next full file name
pointer	pixfile			# pointer to pixel file name
pointer	dp			# directory structure pointer
pointer	im			# image descriptor
pointer	sp, sym, dummy

int	access()
int	drt_gfname()
int	ki_extnode()
int	strmatch()
pointer	drt_open()
pointer	immap()
pointer	stenter()

begin
	# Allocate string space
	call smark (sp)
	call salloc (filename, SZ_PATHNAME, TY_CHAR)
	call salloc (pixfile, SZ_PATHNAME, TY_CHAR)
	call salloc (pathname, SZ_PATHNAME, TY_CHAR)
	call salloc (dummy, 1, TY_CHAR)

	# Open directory
	dp = drt_open (hdrname, SKIP_HIDDEN_FILES)

	# Print title
	call printf ("\n# -- Headers without pixel file in (%s):\n\n")
	    call pargstr (hdrname)
	call flush (STDOUT)

	# Loop over all files in the directory
	while (drt_gfname (dp, Memc[filename], SZ_PATHNAME) != EOF) {

	    # Test only image files (*.imh)
	    if (strmatch (Memc[filename], ".imh$") != 0) {
	
		# Test pixel file for each image
		iferr {

		    # Map image and get pixel file name
		    im = immap (Memc[filename], READ_ONLY, 0)
		    call imgstr (im, "i_pixfile", Memc[pixfile], SZ_PATHNAME)

		    # Get node name offset if desired
		    if (ignore)
			offset = ki_extnode (Memc[pixfile], Memc[dummy], 1, n)
		    else
			offset = 0

		    # If pixel file exists then enter it into the
		    # symbol table. Otherwise send warning message.
		    if (access (Memc[pixfile], 0, 0) == YES) {

			# Enter pixel file name flag for later use 
			sym = stenter (pixtable, Memc[pixfile + offset], 0)
			
			# Verbose output
			if (verbose) {
			    call printf ("# %s -> %s ...OK\n")
				call pargstr (Memc[filename])
				call pargstr (Memc[pixfile + offset])
			}

		    } else {
			call fpathname (Memc[filename], Memc[pathname],
					SZ_PATHNAME)
			call printf ("imdelete %s, verify=%b\n")
			    call pargstr (Memc[pathname])
			    call pargb (verify)
		    }

		    # Unmap image
		    call imunmap (im)

		} then
		    call erract (EA_WARN)
	    }
	}

	# Flush standard output for every directory
	call flush (STDOUT)

	# Close directory
	call drt_close (dp)

	# Free memory
	call sfree (sp)
end


# IMTS_PIXELS -- Traverse a pixel files directory looking for pixel
# files not present in the sumbol table, previouly constructed by
# the imts_headers() procedure. In this way, this procedure finds
# all the pixel file with no header in the headers directory.

procedure imts_pixels (pixname, pixtable, verbose, verify, ignore)

char	pixname[ARB]		# directory name
pointer	pixtable		# pixels table
bool	verbose			# verbose output ?
bool	verify			# delete verification ?
bool	ignore			# ignore node name ?

int	offset			# node string offset
int	n
pointer	filename		# pointer to next file name
pointer	pathname		# pointer t full path name
pointer	dp			# directory structure pointer
pointer	sym, sp, dummy

int	drt_gfname()
int	ki_extnode()
int	strmatch()
pointer	drt_open()
pointer	stfind()

begin
	# Allocate string space
	call smark (sp)
	call salloc (filename, SZ_PATHNAME, TY_CHAR)
	call salloc (pathname, SZ_PATHNAME, TY_CHAR)
	call salloc (dummy, 1, TY_CHAR)

	# Open directory
	dp = drt_open (pixname, SKIP_HIDDEN_FILES)

	# Print title
	call printf ("\n# -- Pixel files without header in (%s):\n\n")
	    call pargstr (pixname)
	call flush (STDOUT)

	# Loop over all files in the directory
	while (drt_gfname (dp, Memc[filename], SZ_PATHNAME) != EOF) {

	    # Test only pixel files (*.pix)
	    if (strmatch (Memc[filename], ".pix$") != 0) {

		# Get full pathname. This is necessary to perform the
		# string comparison since VFN are not used in the image
		# headers.
		call fpathname (Memc[filename], Memc[pathname], SZ_PATHNAME)

		# Get node name offset if desired
		if (ignore)
		    offset = ki_extnode (Memc[pathname], Memc[dummy], 1, n)
		else
		    offset = 0

		# Test if it's in the pixel table. Verbose 
		# output if necessary.
		sym = stfind (pixtable, Memc[pathname + offset])
		if (sym != NULL) {
		    if (verbose) {
			call printf ("# %s ...OK\n")
			    call pargstr (Memc[pathname + offset])
		    }
		} else {
		    call printf ("delete %s verify=%b\n")
			call pargstr (Memc[pathname])
			call pargb (verify)
		}
	    }
	}

	# Flush standard output for every directory
	call flush (STDOUT)

	# Close directory
	call drt_close (dp)

	# Free memory
	call sfree (sp)
end
