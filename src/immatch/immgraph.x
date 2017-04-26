include	<pkg/gtools.h>

# Help file name and prompt
define	IMM_HELP		"ctio$lib/scr/immatch.key"
define	IMM_PROMPT		"immatch interactive commands"

# Graph types
define	INPUT_LINES		1		# input lines
define	INPUT_COLUMNS		2		# input columns
define	CORR_LINE		3		# correlated line
define	CORR_COLUMN		4		# correlated column


# IMM_GRAPH -- Graph input and correlated line and columns

procedure imm_graph (gp, gt, inname, refname,incol, inline, refcol, refline,
		     nlines, npix, ndim, corrcol, corrline, nclines, ncpix,
		     colcen, linecen)

pointer	gp					# GIO pointer
pointer	gt					# GTOOLS pointer
char	inname[ARB]				# input image name
char	refname[ARB]				# reference image name
real	incol[npix], inline[npix]		# input line and column
real	refcol[nlines], refline[nlines]		# reference line and column
int	nlines					# number of input lines
int	npix					# number of input pixels
int	ndim					# number of dimensions
real	corrcol[nclines], corrline[ncpix]	# correlated line and column
int	nclines					# number of correlated lines
int	ncpix					# number of correlated pixels 
real	colcen, linecen				# centroid positions

int	wcs, key
int	overplot, newgraph, ptype
real	wx, wy
real	xlimit
pointer	cmd, str, sp

int	gt_gcur1()

begin
	# Allocate string space
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Initialize variables
	key = 'r'
	overplot = NO
	newgraph = YES
	ptype = INPUT_LINES

	# Loop reading cursor commands
	repeat {
	    switch (key) {
	    case '?': # Print help text.
		call gpagefile (gp, IMM_HELP, IMM_PROMPT)

	    case ':': # List or set parameters
		if (Memc[cmd] == '/')
	            call gt_colon (Memc[cmd], gp, gt, newgraph)
		else
		    call imm_colon (Memc[cmd], gp, gt, newgraph)

	    case 'c': # Plot input column
		if (ptype != INPUT_COLUMNS && ndim > 1) {
		    ptype = INPUT_COLUMNS
		    newgraph = YES
		}

	    case 'l': # Plot input line
		if (ptype != INPUT_LINES) {
		    ptype = INPUT_LINES
		    newgraph = YES
		}

	    case 'o' : # Overplot next graph
		overplot = YES

	    case 'x' : # Plot correlated line
		if (ptype != CORR_LINE && ndim > 1) {
		    ptype = CORR_LINE
		    newgraph = YES
		}

	    case 'y' : # Plot correlated column
		if (ptype != CORR_COLUMN) {
		    ptype = CORR_COLUMN
		    newgraph = YES
		}

	    case 'r': # Redraw the graph
		newgraph = YES

	    case 'w':  # Window graph
		call gt_window (gt, gp, "cursor", newgraph)

	    case 'I': # Interrupt
		call fatal (0, "Interrupt")
	    }

	    # Redraw the graph if necessary
	    if (newgraph == YES) {

		# Branch on graph type
		switch (ptype) {
		case INPUT_COLUMNS:

		    if (overplot == NO) {
			call gclear (gp)

			call sprintf (Memc[str], SZ_LINE,
			"Input and reference columns\ninput=%s, reference=%s")
			    call pargstr (inname)
			    call pargstr (refname)
			call gt_sets (gt, GTTITLE, Memc[str])

			call gt_sets (gt, GTXLABEL, "pixel")
			call gt_sets (gt, GTTYPE, "line")

			call gswind (gp, 1.0, real (nlines), INDEFR, INDEFR)
			call gascale (gp, incol, nlines, 2)
			call grscale (gp, refcol, nlines, 2)
			call gt_swind (gp, gt)
			call gt_labax (gp, gt)
		    }

		    call gt_vplot (gp, gt, incol, nlines, 1.0, real (nlines))
		    call gt_vplot (gp, gt, refcol, nlines, 1.0, real (nlines))

		case INPUT_LINES:

		    if (overplot == NO) {
			call gclear (gp)

			call sprintf (Memc[str], SZ_LINE,
			"Input and reference lines\ninput=%s, reference=%s")
			    call pargstr (inname)
			    call pargstr (refname)
			call gt_sets (gt, GTTITLE, Memc[str])

			call gt_sets (gt, GTXLABEL, "pixel")
			call gt_sets (gt, GTTYPE, "line")

			call gswind (gp, 1.0, real (npix), INDEFR, INDEFR)
			call gascale (gp, inline, npix, 2)
			call grscale (gp, refline, npix, 2)
			call gt_swind (gp, gt)
			call gt_labax (gp, gt)
		    }

		    call gt_vplot (gp, gt, inline, npix, 1.0, real (npix))
		    call gt_vplot (gp, gt, refline, npix, 1.0, real (npix))

		case CORR_COLUMN:

		    if (overplot == NO) {
		        call gclear (gp)

			call sprintf (Memc[str], SZ_LINE,
			"Correlated column: shift = %g\ninput=%s, reference=%s")
			    call pargr (colcen)
			    call pargstr (inname)
			    call pargstr (refname)
			call gt_sets (gt, GTTITLE, Memc[str])

			call gt_sets (gt, GTXLABEL, "lag")
			call gt_sets (gt, GTTYPE, "line")

			xlimit = real (nclines / 2)

			call gswind (gp, - xlimit, xlimit - 1, INDEFR, INDEFR)
			call gascale (gp, corrcol, nclines, 2)
			call gt_swind (gp, gt)
			call gt_labax (gp, gt)
		    }

		    call gt_vplot (gp, gt, corrcol, nclines,
				   - xlimit, xlimit - 1)

		case CORR_LINE:

		    if (overplot == NO) {
		        call gclear (gp)

			call sprintf (Memc[str], SZ_LINE,
			"Correlated line: shift = %g\ninput=%s, reference=%s")
			    call pargr (linecen)
			    call pargstr (inname)
			    call pargstr (refname)
			call gt_sets (gt, GTTITLE, Memc[str])

			call gt_sets (gt, GTXLABEL, "lag")
			call gt_sets (gt, GTTYPE, "line")

			xlimit = real (ncpix / 2)

			call gswind (gp, -xlimit, xlimit - 1, INDEFR, INDEFR)
			call gascale (gp, corrline, ncpix, 2)
			call gt_swind (gp, gt)
			call gt_labax (gp, gt)
		    }

		    call gt_vplot (gp, gt, corrline, ncpix,
				   - xlimit, xlimit - 1)

		default:
		    call error (0, "imm_graph: Bad plot type")
		}

		# Clear flags
		newgraph = NO
		overplot = NO
	    }

	} until (gt_gcur1 (gt, "cursor", wx, wy, wcs, key, Memc[cmd],
			   SZ_LINE) == EOF)

	# Free memory
	call sfree (sp)
end


# IMM_COLON -- Interactive colon commands

procedure imm_colon (cmd, gp, gt, newgraph)

char	cmd[ARB]		# command string
pointer	gp, gt
int	newgraph

begin
	# None so far
end
