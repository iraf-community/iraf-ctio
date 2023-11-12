include	<error.h>
include	<gki.h>
include	"cad.h"


# T_GKI2CAD -- Convert a list of GKI metacode files into an autoCAD
# DXF format file. Text is optionally written to the output file. All
# GKI instructions are written to the output file as comments if verbose
# output is selected. Only a subset of the GKI instruction has a DXF
# equivalent.

procedure t_gki2cad ()

bool	text			# output text ?
bool	verbose			# verbose output ?
char	fname[SZ_FNAME]		# input file name
char	output[SZ_FNAME]	# output file name
int	inlist			# input file list
int	fd			# file descriptors
pointer	cd			# CAD descriptor
pointer	gki			# GKI buffer

bool	clgetb()
int	open()
int	clpopni(), clgfil()
int	gki_fetch_next_instruction()
pointer	cad_open()

begin
	# Get parameters
	inlist = clpopni ("gkifiles")
	call clgstr ("cadfile", output, SZ_FNAME)
	text = clgetb ("text")
	verbose = clgetb ("verbose")

	# Open CAD file, and start "entities" section
	cd = cad_open (output, NEW_FILE, TEXT_FILE)
	call cad_startsec (cd, SEC_ENTITIES)

	# Loop over files in the input list
	while (clgfil (inlist, fname, SZ_FNAME) != EOF) {

	    # Open input file
	    iferr (fd = open (fname, READ_ONLY, BINARY_FILE)) {
		call erract (EA_WARN)
		next
	    }

	    # Process the metacode instruction stream.
	    while (gki_fetch_next_instruction (fd, gki) != EOF)
		call cad_decode (cd, Mems[gki], text, verbose)

	    # Close input file
	    call close (fd)
	}

	# End "entitities" section, and close CAD file
	call cad_endsec (cd)
	call cad_close (cd)

	# Close all
	#call mfree (gki, TY_SHORT)
	call clpcls (inlist)
end


# CAD_DECODE -- Decode a metacode instruction. The instruction is decoded
# and the equivalent DXF format instruction (if any) is written to the
# output file.

procedure cad_decode (cd, gki, text, verbose)

pointer	cd			# CAD descriptor
short	gki[ARB]		# graphics kernel instruction
bool	text			# output text ?
bool	verbose			# verbose output with comments ?

char	comment[SZ_LINE]
short	instr
int	up, size, space, path
int	hjust, vjust
int	font, qlty, ci
int	x, y
int	npts, nchars

begin
	# Get instruction
	instr = gki[GKI_HDR_OPCODE]

	# Branch on GKI instruction code
	switch (instr) {

	case GKI_OPENWS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_OPENWS (NEQ)")

	case GKI_CLOSEWS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_CLOSEWQ (NEQ)")

	case GKI_REACTIVATEWS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_REACTIVATEWS (NEQ)")

	case GKI_DEACTIVATEWS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_DEACTIVATEWS (NEQ)")

	case GKI_MFTITLE:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_MFTITLE (NEQ)")

	case GKI_CLEAR:			# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_CLEAR (NEQ)")

	case GKI_CANCEL:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_CANCEL (NEQ)")

	case GKI_FLUSH:			# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_FLUSH (NEQ)")

	case GKI_POLYLINE:

	    # Get polyline parameters
	    npts = gki[GKI_POLYLINE_N]

	    # Verbose
	    if (verbose) {
		call sprintf (comment, SZ_LINE, "GKI_POLYLINE, npts=%d")
		    call pargi (npts)
		call cad_comment (cd, comment)
	    }

	    # Write polyline
	    call cad_polyline (cd, gki[GKI_POLYLINE_P], npts)

	case GKI_POLYMARKER:

	    # Get polymarker parameters
	    npts = gki[GKI_POLYMARKER_N]

	    # Verbose
	    if (verbose) {
		call sprintf (comment, SZ_LINE, "GKI_POLYMARKER, npts=%d")
		    call pargi (npts)
		call cad_comment (cd, comment)
	    }

	    # Write polymarker
	    call cad_polyline (cd, gki[GKI_POLYMARKER_P], npts)

	case GKI_TEXT:

	    # Get text parameters
	    x      = gki[GKI_TEXT_P]
	    y      = gki[GKI_TEXT_P+1]
	    nchars = gki[GKI_TEXT_N]

	    # Verbose
	    if (verbose) {
		call sprintf (comment, SZ_LINE,
		    "GKI_TEXT, x=%d, y=%d, nchars=%d")
		    call pargi (x)
		    call pargi (y)
		    call pargi (nchars)
		call cad_comment (cd, comment)
	    }

	    # Write text
	    if (text) {
		call cad_layer (cd, LAYER_TEXT)
	        call cad_text (cd, x, y, gki[GKI_TEXT_T], nchars)
		call cad_layer (cd, LAYER_DATA)
	    }

	case GKI_FILLAREA:		# not implemented yet

	    # Get area parameters
	    npts = gki[GKI_FILLAREA_N]

	    # Verbose
	    if (verbose) {
		call sprintf (comment, SZ_LINE, "GKI_FILLAREA, npts=%d (NI)")
		    call pargi (npts)
		call cad_comment (cd, comment)
	    }

	    # Write filled area
	    # NOT IMPLEMENTED

	case GKI_PUTCELLARRAY:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_PUTCELLARRAY (NEQ)")

	case GKI_SETCURSOR:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_SETCURSOR (NEQ)")

	case GKI_PLSET:			# not implemented yet

	    # Verbose
	    if (verbose)
		call cad_comment (cd, "GKI_PLSET (NI)")

	    # Set polyline attributes
	    # NOT IMPLEMENTED

	case GKI_PMSET:			# not implemented yet

	    # Verbose
	    if (verbose)
		call cad_comment (cd, "GKI_PMSET (NI)")

	    # Set polymarker attributes
	    # NOT IMPLEMENTED

	case GKI_TXSET:			# not implemented yet

	    # Get text parameters
	    up    = gki[GKI_TXSET_UP]
	    size  = gki[GKI_TXSET_SZ]
	    space = gki[GKI_TXSET_SP]
	    path  = gki[GKI_TXSET_P]
	    hjust = gki[GKI_TXSET_HJ]
	    vjust = gki[GKI_TXSET_VJ]
	    font  = gki[GKI_TXSET_F]
	    qlty  = gki[GKI_TXSET_Q]
	    ci    = gki[GKI_TXSET_CI]

	    # Verbose
	    if (verbose) {
		call sprintf (comment, SZ_LINE, "GKI_TXSET up=%d, size=%d, space=%d, path=%d, hjust=%d, vjust=%d, font=%d, qlty=%d, ci=%d (NI)")
		    call pargi (up)
		    call pargi (size)
		    call pargi (space)
		    call pargi (path)
		    call pargi (hjust)
		    call pargi (vjust)
		    call pargi (font)
		    call pargi (qlty)
		    call pargi (ci)
		call cad_comment (cd, comment)
	    }

	    # Set text parameters
	    # PARTIALLY IMPLEMENTED
	    call cad_txset (cd, size)

	case GKI_FASET:			# not implemented yet

	    # Verbose
	    if (verbose)
		call cad_comment (cd, "GKI_FASET (NI)")

	    # Set fill area attributes
	    # NOT IMPLEMENTED

	case GKI_GETCURSOR:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_GETCURSOR (NEQ)")

	case GKI_GETCELLARRAY:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_GETCELLARRAY (NEQ)")

	case GKI_ESCAPE:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_ESCAPE (NEQ)")

	case GKI_SETWCS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_SETWCS (NEQ)")

	case GKI_GETWCS:		# no equivalent
	    if (verbose)
		call cad_comment (cd, "GKI_GETWCS (NEQ)")

	default:
	    call sprintf (comment, SZ_LINE,
		"Warning: Unknown GKI instruction %d\n")
		call pargs (instr)
	}
end
