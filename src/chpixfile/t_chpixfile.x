include	<chars.h>
include	<error.h>
include	<pkg/xtanswer.h>

# Strings used to flag the use of the the same node and image directory
# specified in the image header.
define	SAME_IMDIR	"*"
define	SAME_NODE	"*"

# Node and directory delimiters. These delimiters are defined as strings
# and characters to simplify calling sequences in the program.
define	NODE_DELIM	"!"
define	DIR_DELIM	"/"
define	DIR_DELIM_CH	'/'

# String used to specify that the pixel file is stored in the same directory
# as the image header. This is a special case in the pixel file name spec.
define	HDR_DIR		"HDR$"


# T_CHPIXFILE -- Change pixel file name in a list of image headers.

procedure t_chpixfile()

bool	show			# show operations ?
bool	verify			# verify each operation ?
bool	update			# enable updating of the image header ?
char	value[SZ_PATHNAME]	# pixel file name value
int	imlist			# input image list
int	answer			# user's answer to verify prompt
pointer	im			# input image descriptor
pointer	image			# input image name
pointer	node			# node name
pointer	imdir			# imdir
pointer	sp

bool	clgetb()
int	clpopnu(), clgfil()
pointer	immap()

begin
	# Get parameters
	imlist = clpopnu ("images")
	call clgstr ("value", value, SZ_PATHNAME)
	show   = clgetb ("show")
	verify = clgetb ("verify")
	update = clgetb ("update")

	# Reset verify flag if the update flag is not set, and
	# set the show flag if the verify flag is set.
	verify = verify && update
	show   = show || verify

	# Initialize answer to verify prompt
	answer = YES

	# Allocate string space
	call smark  (sp)
	call salloc (image, SZ_FNAME,    TY_CHAR)
	call salloc (node,  SZ_PATHNAME, TY_CHAR)
	call salloc (imdir, SZ_PATHNAME, TY_CHAR)

	# Parse value specification
	call chp_parse2 (value,  Memc[node], Memc[imdir])

	# Loop over images in the input list
	while (clgfil (imlist, Memc[image], SZ_FNAME) != EOF) {

	    # Open input image
	    iferr (im = immap (Memc[image], READ_WRITE, 0)) {
		call erract (EA_WARN)
		next
	    }

	    # Process image
	    call chp_proc (im, Memc[image], Memc[node], Memc[imdir],
			   show, update, verify, answer)

	    # Close image
	    call imunmap (im)

	    # Stop if the answer is ALWAYSNO
	    if (answer == ALWAYSNO)
		break
	}

	# Free memory and close image list
	call sfree  (sp)
	call clpcls (imlist)
end


# CHP_PROC -- Change the pixel file name in a single image header. Build
# the new pixel file based on the pixel file name in the image header and
# the value supplied by the user. A null node specified by the user is
# interpreted as removing the node name from the image header.

procedure chp_proc (im, image, usr_node, usr_imdir, show, update, verify,
		    answer)

pointer	im			# input image descriptor
char	image[ARB]		# input image name
char	usr_node[ARB]		# user specified node name
char	usr_imdir[ARB]		# user specified image directory
bool	show			# show operations ?
bool	verify			# verify each operation ?
bool	update			# enable updating of the image header ?
int	answer			# user's answer to verify prompt (modified)

int	len
pointer	sp
pointer	im_pixfile, im_node, im_imdir, im_fname
pointer	new_pixfile, new_node, new_imdir
pointer	prompt

bool	strne()
int	strlen(), strsearch()

begin
	# Allocat string space
	call smark  (sp)
	call salloc (new_pixfile, SZ_PATHNAME, TY_CHAR)
	call salloc (new_node,    SZ_LINE,     TY_CHAR)
	call salloc (new_imdir,   SZ_PATHNAME, TY_CHAR)
	call salloc (im_pixfile,  SZ_PATHNAME, TY_CHAR)
	call salloc (im_node,     SZ_LINE,     TY_CHAR)
	call salloc (im_imdir,    SZ_PATHNAME, TY_CHAR)
	call salloc (im_fname,    SZ_FNAME,    TY_CHAR)
	call salloc (prompt,      SZ_LINE,     TY_CHAR)

	# Get the full pixel file name specification from the image
	# header and extract the node name and the pixel file name.
	call imgstr (im, "i_pixfile", Memc[im_pixfile], SZ_PATHNAME)
	iferr (call chp_parse3 (Memc[im_pixfile], Memc[im_node],
				Memc[im_imdir], Memc[im_fname])) {
	    call erract (EA_WARN)
	    call sfree (sp)
	    return
	}

#call eprintf ("pixfile=(%s), node=(%s), imdir=(%s), fname=(%s)\n")
#call pargstr (Memc[im_pixfile])
#call pargstr (Memc[im_node])
#call pargstr (Memc[im_imdir])
#call pargstr (Memc[im_fname])

	# Determine the new node name and image directory based on
	# the user specification and the header information
	if (strne (usr_node, SAME_NODE))
	    call strcpy (usr_node, Memc[new_node], SZ_LINE)
	else
	    call strcpy (Memc[im_node], Memc[new_node], SZ_LINE)
	if (strne (usr_imdir, SAME_IMDIR))
	    call strcpy (usr_imdir, Memc[new_imdir], SZ_PATHNAME)
	else
	    call strcpy (Memc[im_imdir], Memc[new_imdir], SZ_PATHNAME)

	# Return inmediately if there is a node specification when the
	# the image directory is the special case of the pixel file
	# in the same directory as the image header.
	if (strlen (Memc[new_node]) > 0 &&
	    strsearch (Memc[new_imdir], HDR_DIR) > 0) {
	    call eprintf (
		"Warning: Node cannot be specified if imdir is %s for %s\n")
		call pargstr (HDR_DIR)
		call pargstr (image)
	    call sfree (sp)
	    return
	}

	# Append a trailing slash to non-empty image directories that
	# do not have it, except for the special case of the pixel file
	# in the same directory as the image header.
	len = strlen (Memc[new_imdir])
	if (len > 0 && strne (Memc[new_imdir], HDR_DIR) &&
	    Memc[new_imdir + len - 1] != DIR_DELIM_CH)
	    call strcat (DIR_DELIM, Memc[new_imdir], SZ_PATHNAME)

	# Build the new full pixel file name specification
	if (strlen (Memc[new_node]) > 0) {
	    call sprintf (Memc[new_pixfile], SZ_LINE, "%s%s%s%s")
		call pargstr (Memc[new_node])
		call pargstr (NODE_DELIM)
		call pargstr (Memc[new_imdir])
		call pargstr (Memc[im_fname])
	} else {
	    call sprintf (Memc[new_pixfile], SZ_LINE, "%s%s")
		call pargstr (Memc[new_imdir])
		call pargstr (Memc[im_fname])
	}

	# Print operation if the show flag is set
	if (show) {
	    call printf ("%s: %s -> %s\n")
		call pargstr (image)
		call pargstr (Memc[im_pixfile])
		call pargstr (Memc[new_pixfile])
	    call flush (STDOUT)
	}

	# Prompt the user for verification if the verify flag is set,
	# and if the user didn't answer ALWAYSYES in the prevoius image.
	if (verify && answer != ALWAYSYES) {
	    call sprintf (Memc[prompt], SZ_LINE, "update %s ?")
		call pargstr (image)
	    call xt_answer (Memc[prompt], answer)
	}

	# Update image header if the update flag is set
	if (update && (answer == YES || answer == ALWAYSYES)) {
	    call impstr (im, "i_pixfile", Memc[new_pixfile])
	    if (show) {
		call printf ("%s updated\n")
		    call pargstr (image)
	    }
	} else if (show) {
	    call printf ("%s not updated\n")
		call pargstr (image)
	}

	# Free memory
	call sfree (sp)
end


# CHP_PARSE2 -- Parse a full pixel file name specification and return the
# node name and the pixel file name. The node name and the pixel file name
# are delimited delimited by the "!" character, if any. If this character is
# not present the output node will be null.

procedure chp_parse2 (pixfile, node, pixname)

char	pixfile[ARB]		# pixel file node and directory specification
char	node[SZ_LINE]		# node name (output)
char	pixname[SZ_PATHNAME]	# pixel file name (output)

int	n

int	stridxs()

begin
	# Issue an error if the input value contains blanks
	if (stridxs (" ", pixfile) > 0)
	    call error (0, "Blanks are not allowed in the pixel file name")

	# Look for the node delimiter and extract the node and image
	# directory from the value. A null node is returned if no
	# delimiter is found.
	n = stridxs (NODE_DELIM, pixfile)
	if (n > 0) {
	    call strcpy (pixfile,        node,    n - 1)
	    call strcpy (pixfile[n + 1], pixname, SZ_PATHNAME)
	} else {
	    call strcpy ("",      node,    SZ_LINE)
	    call strcpy (pixfile, pixname, SZ_PATHNAME)
	}
end


# CHP_PARSE3 -- Parse a full pixel file name specification and return the
# node name, the image directory, and file name. The node name and the image
# directory might be null.

procedure chp_parse3 (pixfile, node, imdir, fname)

char	pixfile[ARB]		# pixel file node and directory specification
char	node[SZ_LINE]		# node name (output)
char	imdir[SZ_PATHNAME]	# image directory (output)
char	fname[SZ_FNAME]		# file name (output)

int	n, m
pointer	sp, pixname

int	strldxs(), strsearch()
errchk	chp_parse2()

begin
	# Allocate string space
	call smark  (sp)
	call salloc (pixname, SZ_PATHNAME, TY_CHAR)

	# Parse node name and pixel file name
	iferr (call chp_parse2 (pixfile, node, Memc[pixname])) {
	    call sfree (sp)
	    call erract (EA_ERROR)
	}

	# Split the pixel file name into an image directory and a file name
	n = strsearch (Memc[pixname], HDR_DIR)
	m = strldxs   (DIR_DELIM,     Memc[pixname])
	if (m > 0) {
	    call strcpy (Memc[pixname],     imdir, m)
	    call strcpy (Memc[pixname + m], fname, SZ_FNAME)
	} else if (n > 0) {
	    call strcpy (Memc[pixname],         imdir, n - 1)
	    call strcpy (Memc[pixname + n - 1], fname, SZ_FNAME)
	} else {
	    call strcpy ("",            imdir, SZ_PATHNAME)
	    call strcpy (Memc[pixname], fname, SZ_FNAME)
	}

	# Free memory
	call sfree (sp)
end
