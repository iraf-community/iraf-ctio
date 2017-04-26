include	<imhdr.h>
include	<pkg/gtools.h>
include	<pkg/xtanswer.h>
include	"idsmtn.h"
include "spcombine.h"

# Line fugde modes
define	FL_CURSOR	0
define	FL_SPECTRUM	1

# Shift modes
define	SHIFT_CURSOR	0
define	SHIFT_AVERAGE	1
define	SHIFT_ACCUM	2

# Edit structure
define	LEN_EDT		8
define	S1		Memr[$1+0]
define	S2		Memr[$1+1]
define	S1DEF		Memr[$1+2]
define	S2DEF		Memr[$1+3]
define	A1		Memr[$1+4]
define	A2		Memr[$1+5]
define	A1DEF		Memr[$1+6]
define	A2DEF		Memr[$1+7]


# EDIT_SPECTRUM - Edit the input spectrum interactively

procedure edit_spectrum (gp, gt, inspec, outspec, ispec, nspec, mode, command)

pointer	gp			# graphics descriptor
pointer	gt			# GTOOLS graphics descriptor
pointer	inspec			# input spectrum structure
pointer	outspec			# output spectrum structure
int	ispec			# spectrum number
int	nspec			# total number of spectra
int	mode			# interpolation mode
int	command			# command to calling procedure (output)

char	str[SZ_LINE]		# colon mode string
bool	additive		# additive shifts ?
int	redraw			# redisplay graph ?
int	key			# keystroke value
int	wcs			# world coordinate system
int	cx			# pixel cursor position
int	p1, p2
int	answer			# user's answer to confirmation
real	wx, wy			# cursor coordinates
pointer	edt			# editor structure
pointer	sp

bool	clgetb()
int	clgcur()

begin
	if (clgetb ("debug")) {
	    call eprintf ("edit_spectrum: gp=<%d> gt=<%d> in=<%d> out=<%d> mode=<%d> cmd=<%d>\n")
		call pargi (gp)
		call pargi (gt)
		call pargi (inspec)
		call pargi (outspec)
		call pargi (mode)
		call pargi (command)
	}

	# Allocate space for editor structure
	call smark (sp)
	call salloc (edt, LEN_EDT, TY_STRUCT)

	# Get editor input and overlap ranges
	call default_ranges (inspec, outspec, edt)

	# Set graph title
	call sprintf (str, SZ_LINE,
	    "%d of %d   %-10.10s   In: %.2f:%.2f   Ov: %.2f:%.2f" )
	    call pargi (ispec)
	    call pargi (nspec)
	    call pargstr (IM_TITLE (IN_IM (inspec)))
	    call pargr (S1DEF (edt))
	    call pargr (S2DEF (edt))
	    call pargr (A1DEF (edt))
	    call pargr (A2DEF (edt))
	call gt_sets (gt, GTTITLE, str)

	# Enter cursor loop with "additive shift" keystroke
	# and forcing a replot of the spectra
	key = '+'
	redraw = YES
	repeat {

	    # Process option
	    switch (key) {
	    case 'a': # mark ranges in overlap region
		if (IS_INDEFR (A1 (edt)) && IS_INDEFR (A2 (edt)))
		    call get_range (wx, A1 (edt), A2 (edt),
				    max (S1 (edt), A1DEF (edt)),
				    min (S2 (edt), A2DEF (edt)))
	    case 'b': # forget a's
		A1 (edt) = A1DEF (edt)
		A2 (edt) = A2DEF (edt)
	    case 'c': # print cursor position
		call printf ("cursor x,y: %.2f %.2f  (%d)\n")
		    call pargr (wx)
		    call pargr (wy)
		    call pargi (OUT_INDEX (outspec, wx))
	    case 'd': # replace range in input spectrum by line segment
		call fudge_line (inspec, edt, wx, wy, FL_CURSOR)
		redraw = YES
	    case 'e' : # replace range in input spectrum by line segment
		call fudge_line (inspec, edt, wx, wy, FL_SPECTRUM)
		redraw = YES
	    case 'f': # go to the beggining
		answer = NO
		call xt_answer ("Start ALL over again", answer)
		if (answer == YES || answer == ALWAYSYES) {
	    	    command = COMB_FIRST
		    break
		}
	    case 'j': # replace pixel by vertical cursor value
	        cx = IN_INDEX (inspec, wx)
		Memr[IN_PIX (inspec) + cx - 1] = wy
		redraw = YES
	    case 'n': # next spectrum
		answer = YES
		call xt_answer ("Continue with next spectrum", answer)
		if (answer == YES || answer == ALWAYSYES) {
		    command = COMB_NEXT
		    break
		}
	    case 'o': # reset input spectrum
		answer = NO
		call xt_answer ("Reset input spectrum", answer)
		if (answer == YES || answer == ALWAYSYES) {
		    command = COMB_AGAIN
		    break
		}
	    case 'p':
		answer = NO
		call xt_answer ("Skip current spectrum", answer)
		if (answer == YES || answer == ALWAYSYES) {
		    command = COMB_SKIP
		    break
		}
	    case 'q': # done
		answer = NO
		call xt_answer ("Carry on blindly next spectra", answer)
		if (answer == YES || answer == ALWAYSYES) {
		    command = COMB_BLIND
		    break
		}
	    case 'r': # redraw
		redraw = YES
	    case 's': # mark ranges in input spectrum
		call get_range (wx, S1(edt), S2(edt), S1DEF(edt), S2DEF(edt))
		if (IS_INDEFR (A1 (edt)) && IS_INDEFR (A2 (edt))) {
		    A1 (edt) = max (S1 (edt), A1 (edt))
		    A2 (edt) = min (S2 (edt), A2 (edt))
		}
		redraw = YES
	    case 't': # forget s's
		if (S1 (edt) == A1 (edt))
		    A1 (edt) = A1DEF (edt)
		if (S2 (edt) == A2 (edt))
		    A2 (edt) = A2DEF (edt)
		S1 (edt) = S1DEF (edt)
		S2 (edt) = S2DEF (edt)
		redraw = YES
	    case 'v': # shift input spectrum vertically (average)
		call shift_vert (inspec, outspec, edt, wx, wy,
				 SHIFT_AVERAGE, additive, redraw)
	    case 'w': # window
		call gt_window (gt, gp, "cursor", redraw)
	    case 'x': # shift input spectrum vertically
		call shift_horiz (inspec, wx, mode)
		call default_ranges (inspec, outspec, edt)
		redraw = YES
	    case 'y': # shif input spectrum vertically (cursor)
		call shift_vert (inspec, outspec, edt, wx, wy,
				 SHIFT_CURSOR, additive, redraw)
	    case 'z': # shift input spectrum vertically (value)
		call shift_vert (inspec, outspec, edt, wx, wy,
				 SHIFT_ACCUM, additive, redraw)
	    case '+': # set additive scaling in vertical shifts
		additive = true
	    case '*': # set multipliacative scaling in vertical shifts
		additive = false
	    case '?': # help screen
		call gpagefile (gp, KEY, PROMPT)
	    }

	    # Redraw actions
	    if (redraw == YES) {

		# Replot spectrum
		p1 = IN_INDEX (inspec, S1 (edt))
		p2 = IN_INDEX (inspec, S2 (edt))
		call plot_spectra (gp, gt,
				   Memr[OUT_PIX (outspec)],
				   Memr[IN_PIX (inspec) + p1 - 1],
				   OUT_NPIX (outspec), p2 - p1 + 1,
				   OUT_W0 (outspec), OUT_W1 (outspec),
				   S1 (edt), S2 (edt))

		# Mark spectrum as already plotted
		redraw = NO

		# Print current limits
		call printf ("Input: %.1f:%.1f   Overlap: %.1f:%.1f\n")
		    call pargr (S1 (edt))
		    call pargr (S2 (edt))
		    call pargr (A1 (edt))
		    call pargr (A2 (edt))
	    }

	} until (clgcur ("cursor", wx, wy, wcs, key, str, SZ_LINE) == EOF)

	# Update input spectrum data according with
	# edit wavelengths
	p1 = IN_INDEX (inspec, S1 (edt))
	p2 = IN_INDEX (inspec, S2 (edt))
	call amovkr (BAD_PIX, Memr[IN_PIX (inspec)], p1 - 1)
	call amovkr (BAD_PIX, Memr[IN_PIX (inspec) + p2],
		     IN_NPIX (inspec) - p2)

	# Free memory
	call sfree (sp)
end


# DEFAULT_RANGES - Get the ranges of the input spectrum to be included in the
# accumulation and ovelap region with the accumulated spectrum.

procedure default_ranges (inspec, outspec, edt)

pointer	inspec			# input spectrum structure
pointer	outspec			# output spectrum structure
pointer	edt			# editor structure

bool	flag
int	i, i1, i2, o1, o2
pointer	pixin, pixout

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("default_ranges: in=<%d> out=<%d> edt=<%d>\n")
		call pargi (inspec)
		call pargi (outspec)
		call pargi (edt)
	}

	# Set flags
	flag = true

	# Input region
	S1 (edt) = IN_W0 (inspec)
	S2 (edt) = IN_W1 (inspec)
	S1DEF (edt) = S1 (edt)
	S2DEF (edt) = S2 (edt)

	# Clear indexes
	o1 = INDEFI
	o2 = INDEFI

	# Determine overlap region
	i1 = max (OUT_INDEX (outspec, IN_W0 (inspec)), 1)
	i2 = min (OUT_INDEX (outspec, IN_W1 (inspec)), OUT_NPIX (outspec))

	do i = i1, i2 {

	    pixin = IN_PIX (inspec) + i - i1
	    pixout = OUT_PIX (outspec) + i - 1

	    if (Memr[pixout] != BAD_PIX && Memr[pixin] != BAD_PIX &&
		flag) {
		o1 = i
		flag = false
	    }
	    if (Memr[pixout] != BAD_PIX && Memr[pixin] != BAD_PIX &&
		!flag)
		o2 = i
	}

	# Convert indexes to wavelength
	if (IS_INDEFI (o1))
	    A1 (edt) = INDEFR
	else
	    A1 (edt) = OUT_WAVE (outspec, o1)
	if (IS_INDEFI (o2))
	    A2 (edt) = INDEFR
	else
	    A2 (edt) = OUT_WAVE (outspec, o2)
	A1DEF (edt) = A1 (edt)
	A2DEF (edt) = A2 (edt)
end


# GET_RANGE - Get a range set by the cursor.

procedure get_range (wx1, low, high, minval, maxval)

real	wx1			# old x cursor position
real	low, high		# new range
real	minval, maxval		# maximum range allowed

char	junkc[1]
int	junki
real	wx2			# new x cursor position
real	junkr

int	clgcur()

begin
	# Prompt the user for next x position
	call printf ("x again:\n")

	# Get next cursor position
	junki = clgcur ("cursor", wx2, junkr, junki, junki, junkc, 1)

	# Swap the values if the first one is
	# greater than the second one
	if (wx1 < wx2) {
	    low = max (wx1, minval)
	    high = min (wx2, maxval)
	} else {
	    low = max (wx2, minval)
	    high = min (wx1, maxval)
	}
end


# FUDGE_LINE - Trace a line between two positions marked by the cursor.
# There are two option to trace the line. The first one will replace the
# values in the array with a line between the x cursor positions and y
# array values. The second one will do it between x and y cursor positions.

procedure fudge_line (inspec, edt, wx1, wy1, mode)

pointer	inspec			# input spectrum structure
pointer	edt			# editor spectrum structure
real	wx1, wy1		# last cursor position
int	mode			# fudging mode

char	strval[SZ_LINE]
int	i, junk
int	cx1, cx2		# cursor position (pixels)
real	slope, base		# line parameters
real	wx2, wy2		# new cursor position

int	clgcur()

begin
	# Prompt the user for next cursor position
	if (mode == FL_CURSOR)
	    call printf ("x,y again:\n")
	else
	    call printf ("x again:\n")

	# Get next cursor position
	junk = clgcur ("cursor", wx2, wy2, junk, junk, strval, SZ_LINE)

	# Evaluate pixel cursor position
	cx1 = min (max (IN_INDEX (inspec, wx1), 1), IN_NPIX (inspec))
	cx2 = max (min (IN_INDEX (inspec, wx2), IN_NPIX (inspec)), 1)

	# Evaluate line paramters
	if (mode == FL_CURSOR) {
	    slope = (wy2 - wy1) / (cx2 - cx1)
	    base = wy1
	} else {
	    slope = (Memr[IN_PIX (inspec) + cx2 - 1] -
		     Memr[IN_PIX (inspec) + cx1 - 1]) / (cx2 - cx1)
	    base = Memr[IN_PIX (inspec) + cx1 - 1]
	}

	# Replace pixel values by line
	do i = cx1, cx2
	    Memr[IN_PIX (inspec) + i - 1] = slope * (i - cx1) + base
end


# SHIFT_HORIZ -  Shift the current spectrum horizontally

procedure shift_horiz (inspec, wx1, mode)

pointer	inspec			# input spectrum structure
real	wx1			# old cursor position
int	mode			# interpolation mode

char	strval[SZ_LINE]
int	junki
real	junkr
real	wx2			# new cursor position
real	dw			# wavelegth difference

bool	clgetb()
int	clgcur()

begin
	if (clgetb ("debug")) {
	    call eprintf ("shift_horiz: inspec=<%d> wx1=<%g> mode<%d>\n")
		call pargi (inspec)
		call pargr (wx1)
		call pargi (mode)
	}

	# Get next cursor position
	call printf ("x again:\n")
	junki = clgcur ("cursor", wx2, junkr, junki, junki, strval, SZ_LINE)

	# Calculate the starting wavlength difference
	dw = wx2 - wx1

	# Assign new data
	IN_W0 (inspec) = IN_W0 (inspec) + dw
	IN_W1 (inspec) = IN_W1 (inspec) + dw
end


# SHIFT_VERT - Shift the current spectrum vertically

procedure shift_vert (inspec, outspec, edt, wx, wy, mode, additive, redraw)

pointer	inspec			# input spectrum structure
pointer	outspec			# output spectrum structure
pointer	edt			# editor structure
real	wx, wy			# cursor position
int	mode			# shifting mode
bool	additive		# additive shift ?
int	redraw			# redraw spectrum ?

int	cx, cx1, cx2
real	avgov, avgin, shift
real	junk

bool	clgetb()

begin
	# Decide how to shift image according to the
	# mode selected
	if (mode == SHIFT_CURSOR) {

	    # Get cursor position and spectrum limits
	    cx  = IN_INDEX (inspec, min (max (wx, S1 (edt)), S2 (edt)))

	    # Compute shift and apply it to the input spectrum
	    if (additive) {
	        shift = wy - Memr[IN_PIX (inspec) + cx - 1]
		call aaddkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
	        redraw = YES
	    } else if (Memr[IN_PIX (inspec) + cx - 1] != 0) {
	        shift = wy / Memr[IN_PIX (inspec) + cx - 1]
		call amulkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
	        redraw = YES
	    } else
	        call printf ("Multiplicative shift on zero level\n")

		if (clgetb ("debug")) {
		    call eprintf ("cx=<%d> shift=<%g>")
			call pargi (cx)
			call pargr (shift)
		}

	} else if (mode == SHIFT_AVERAGE) {

	    # Compute overlap average
	    cx1 = OUT_INDEX (outspec, A1 (edt))
	    cx2 = OUT_INDEX (outspec, A2 (edt))
	    call aavgr (Memr[OUT_PIX (outspec) + cx1 - 1],
			(cx2 - cx1 + 1), avgov, junk)

	    # Compute input average
	    cx1 = IN_INDEX (inspec, S1 (edt))
	    cx2 = IN_INDEX (inspec, S2 (edt))
	    call aavgr (Memr[IN_PIX (inspec) + cx1 - 1],
			(cx2 - cx1 + 1), avgin, junk)

	    # Compute shift and apply it to the input spectrum
	    if (additive) {
	        shift = avgov - avgin
	        call aaddkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
		redraw = YES
	    } else if (avgin != 0) {
	        shift = avgov / avgin
	        call amulkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
		redraw = YES
	    } else 
	        call printf ("Multiplicative shift on zero average\n")

	    	if (clgetb ("debug")) {
		    call eprintf ("avgov=<%g> avgin=<%g> shift=<%g>")
			call pargr (avgov)
			call pargr (avgin)
			call pargr (shift)
		}

	} else if (mode == SHIFT_ACCUM) {

	    # Get cursor position and spectrum limits
	    cx1 = IN_INDEX (inspec, min (max (wx, A1 (edt)), A2 (edt)))
	    cx2 = OUT_INDEX (outspec, min (max (wx, A1 (edt)), A2 (edt)))
	    # cx = OUT_INDEX (outspec, min (max (wx, A1 (edt)), A2 (edt)))

	    # Compute shift and apply it to the input spectrum
	    if (additive) {
	        shift = Memr[OUT_PIX (outspec) + cx2 - 1] -
			Memr[IN_PIX (inspec) + cx1 - 1]
		call aaddkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
	        redraw = YES
	    } else if (Memr[IN_PIX (inspec) + cx1 - 1] != 0) {
	        shift = Memr[OUT_PIX (outspec) + cx2 - 1] /
			Memr[IN_PIX (inspec) + cx1 - 1]
		call amulkr (Memr[IN_PIX (inspec)], shift,
			     Memr[IN_PIX (inspec)], IN_NPIX (inspec))
	        redraw = YES
	    } else
	        call printf ("Multiplicative shift on zero level\n")

		if (clgetb ("debug")) {
		    call eprintf ("cx1=<%d> cx2=<%d> shift=<%g>")
			call pargi (cx1)
			call pargi (cx2)
			call pargr (shift)
		}
	}

	if (clgetb ("debug"))
	    redraw = NO
end
