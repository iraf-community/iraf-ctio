.help
CAD DXF format file output procedures

These procedures are intended to create DXF format files, but only a
small subset of all the features used by autoCAD is actually used.

Entry points:

pointer = cad_open (name, mode, type)		Open CAD file
	  cad_close (cd)			Close CAD file

	  cad_layer (cd, layer)			Set layer name

	  cad_startsec (cd, section)		Put start of section
	  cad_endsec (cd)			Put end of section

	  cad_polyline (cd, p, npts)		Put polyline

	  cad_text (cd, x, y, text, nchars)	Put text

	  cad_comment (cd, comment)		Put comment

Low level entry points:

	  cad_errchk (cd, label)		Check CAD descriptor
	  cdp_coord (cd, x, y, z)		Put primary coordinates
	  cdp_layer (cd)			Put layer name
	  cdp_eof (fd)				Put end of file
.endhelp

include	"dxf.h"
include	"cad.h"

# Output formats
define	INTFORM		"%3.3d\n"		# integer (I3)
define	STRFORM		"%s\n"			# string
define	REALFORM	"%g\n"			# real
define	INTSTRFORM	"%3.3d\n%s\n"		# combined integer and string
define	INTREALFORM	"%3.3d\n%s\n"		# combined integer and real

# Magic number value for CAD structure
define	MAGIC_NUMBER	1387			# magic number value

# Pointer Mem
define	MEMP		Memi

# CAD structure
define	LEN_STRUCT	5			# structure length
define	CAD_MAGIC	Memi[$1+0]		# magic number
define	CAD_FD		Memi[$1+1]		# file descriptor
define	CAD_FTYPE	Memi[$1+2]		# file type
define	CAD_LAYER	MEMP[$1+3]		# pointer to layer name
define	CAD_TEXTSIZE	Memi[$1+4]		# text size


# CAD_OPEN -- Open CAD file.

pointer procedure cad_open (name, mode, type)

int	name			# file name
int	mode			# file mode
int	type			# file type

int	fd
pointer	cd

int	open()

begin
	# Open file
	fd = open (name, mode, type)

	# Allocate CAD structure
	call malloc (cd, LEN_STRUCT, TY_STRUCT)
	call malloc (CAD_LAYER (cd), SZ_LINE, TY_CHAR)

	# Fill structure
	CAD_MAGIC (cd) = MAGIC_NUMBER
	CAD_FD (cd)    = fd
	CAD_FTYPE (cd) = type

	# Set defaults
	call cad_layer (cd, LAYER_DATA)
	call cad_txset (cd, 10)

	# Return structure pointer
	return (cd)
end


# CAD_CLOSE -- Close CAD file.

procedure cad_close (cd)

pointer	cd			# CAD descriptor

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_close")

	# Write end of file
	call cdp_eof (cd)

	# Close file, and free structure
	call close (CAD_FD (cd))
	call mfree (cd, TY_STRUCT)
end


# CAD_LAYER -- Set layer name for the next operation.

procedure cad_layer (cd, layer)

pointer	cd			# CAD descriptor
char	layer[ARB]		# layer name

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_layer")

	# Copy layer name into CAD structure
	call strcpy (layer, Memc[CAD_LAYER (cd)], SZ_LINE)
end


# CAD_STARTSEC -- Start section.

procedure cad_startsec (cd, section)

pointer	cd			# CAD descriptor
int	section			# file section

int	fd

errchk	cad_errchk ()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_startsec")

	# Get file descriptor
	fd = CAD_FD (cd)

	# Print start of section
	call fprintf (fd, INTSTRFORM)
	    call pargi   (GRP_START)
	    call pargstr (SEC_SECTION_ID)

	# Print section name
	call fprintf (fd, INTSTRFORM)
	    call pargi (GRP_NAME)
	switch (section) {
	case SEC_HEADER:
	    call pargstr (SEC_HEADER_ID)
	case SEC_TABLES:
	    call pargstr (SEC_TABLES_ID)
	case SEC_BLOCKS:
	    call pargstr (SEC_BLOCKS_ID)
	case SEC_ENTITIES:
	    call pargstr (SEC_ENTITIES_ID)
	default:
	    call error (0, "cad_starsec: Unknown section")
	}
end


# CAD_ENDSEC -- End section.

procedure cad_endsec (cd)

pointer	cd		# CAD descriptor

int	fd

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_endsec")

	# Get file descriptor
	fd = CAD_FD (cd)

	# Print end of section
	call fprintf (fd, INTSTRFORM)
	    call pargi   (GRP_START)
	    call pargstr (SEC_ENDSEC_ID)
end


# CAD_COMMENT -- Put comment.

procedure cad_comment (cd, comment)

pointer	cd			# CAD descriptor
char	comment[ARB]		# comment string

int	fd

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_comment")

	# Get file descriptor
	fd = CAD_FD (cd)

	# Print
	call fprintf (fd, INTSTRFORM)
	    call pargi   (GRP_COMMENT)
	    call pargstr (comment)
end


# CAD_POLYLINE -- Put a polyline.

procedure cad_polyline (cd, p, npts)

pointer	cd			# CAD descriptor
short	p[ARB]			# data points
int	npts			# number of points

int	i, fd

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_polyline")

	# Get file descriptor
	fd = CAD_FD (cd)

	# Start polyline
	call fprintf (fd, INTSTRFORM)
	    call pargi (GRP_START)
	    call pargstr (ENT_POLYLINE_ID)

	# Print layer name
	call cdp_layer (cd)

	# Print entities follow flag to indicate that
	# a list of vertices follow.
	call fprintf (fd, INTFORM)
	    call pargi (GRP_FOLLOW)
	call fprintf (fd, INTFORM)
	    call pargi (POL_VERTFLAG)

	# Print starting position ?. This has been
	# seen empircally in the DXF files, although
	# there is no justification in the documentation.
	call cdp_coord (cd, 0.0, 0.0, 0.0)

	# Dump data points
	for (i = 1;  i <= 2 * npts;  i = i + 2) {

	    # Print start of vertex
	    call fprintf (fd, INTSTRFORM)
		call pargi (GRP_START)
		call pargstr (ENT_VERTEX_ID)

	    # Print layer name, and vertex coordinates
	    call cdp_layer (cd)
	    call cdp_coord (cd, real (p[i]), real(p[i + 1]), 0.0)
	}

	# Print end of polyline
	call fprintf (fd, INTSTRFORM)
	    call pargi (GRP_START)
	    call pargstr (ENT_SEQEND_ID)
	call flush (fd)
end


# CAD_TXSET -- Set text attributes. So far only text size is set.

procedure cad_txset (cd, size)

pointer	cd			# CAD descriptor
int	size			# text size

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_txset")

	# Enter attribute into the CAD structure
	CAD_TEXTSIZE (cd) = size
end


# CAD_TEXT -- Put a text string.

procedure cad_text (cd, x, y, text, nchars)

pointer	cd			# CAD descriptor
int	x, y			# text coordinates
short	text[ARB]		# text characters
int	nchars			# number of characters

int	fd
pointer	buffer, sp

errchk	cad_errchk()

begin
	# Check CAD descriptor
	call cad_errchk (cd, "cad_text")

	# Get file descriptor
	fd = CAD_FD (cd)

	# Allocate buffer for text
	call smark (sp)
	call salloc (buffer, nchars, TY_CHAR)

	# Convert text from short to char
	call achtsc (text, Memc[buffer], nchars)
	Memc[buffer + nchars] = EOS

	# Print start of text
	call fprintf (fd, INTSTRFORM)
	    call pargi (GRP_START)
	    call pargstr (ENT_TEXT_ID)

	# Print layer name, and text coordinates
	call cdp_layer (cd)
	call cdp_coord (cd, real (x), real (y), 0.0)

	# Print text height
	call fprintf (fd, INTREALFORM)
	    call pargi (GRP_FLOAT1)
	    call pargr (real (CAD_TEXTSIZE (cd)))

	# Print text
	call fprintf (fd, INTSTRFORM)
	    call pargi   (GRP_PRIMARY)
	    call pargstr (Memc[buffer])
	call flush (fd)

	# Free text buffer
	call sfree (sp)
end


# CAD_ERRCHK -- Check CAD descriptor.

procedure cad_errchk (cd, label)

pointer	cd			# CAD descriptor
char	label[ARB]		# string label

char	errmsg[SZ_LINE]

begin
	# Check null pointer and magic number
	if (cd == NULL) {
	    call sprintf (errmsg, SZ_LINE, "%s: Null descriptor")
		call pargstr (label)
	    call error (0, errmsg)
	} else if (CAD_MAGIC (cd) != MAGIC_NUMBER) {
	    call sprintf (errmsg, SZ_LINE, "%s: Bad magic number")
		call pargstr (label)
	    call error (0, errmsg)
	}
end


# CDP_EOF -- Print end of file.

procedure cdp_eof (cd)

pointer	cd		# CAD descriptor

int	fd

begin
	# Get file descriptor
	fd = CAD_FD (cd)

	# Print
	call fprintf (fd, INTSTRFORM)
	    call pargi   (GRP_START)
	    call pargstr (SEC_EOF_ID)
end


# CDP_COORD -- Print primary (x,y,z) coordinates.

procedure cdp_coord (cd, x, y, z)

pointer	cd			# CAD descriptor
real	x, y, z			# coordinates

int	fd

begin
	# Get file descriptor
	fd = CAD_FD (cd)

	# x coordinate
	call fprintf (fd, INTREALFORM)
	    call pargi (GRP_XCOORD)
	    call pargr (x)

	# y coordinate
	call fprintf (fd, INTREALFORM)
	    call pargi (GRP_YCOORD)
	    call pargr (y)

	# z coordinate
	call fprintf (fd, INTREALFORM)
	    call pargi (GRP_ZCOORD)
	    call pargr (z)
end


# CDP_LAYER -- Print layer name already set in the CAd structure.

procedure cdp_layer (cd)

pointer	cd			# CAD descriptor

int	fd

begin
	# Get file descriptor
	fd = CAD_FD (cd)

	# Print layer name
	call fprintf (fd, INTSTRFORM)
	    call pargi (GRP_LAYER)
	    call pargstr (Memc[CAD_LAYER (cd)])
end
