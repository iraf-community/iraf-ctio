include	"spcombine.h"


# INIT_INSPEC - Initialize input spectrum structure

procedure init_inspec (spectrum)

pointer	spectrum		# spectrum structure

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("init_inspec: spec=<%d>\n")
		call pargi (spectrum)
	}

	IN_W0 (spectrum) = INDEFR
	IN_W1 (spectrum) = INDEFR
	IN_WPC (spectrum) = INDEFR
	IN_NPIX (spectrum) = INDEFI
	IN_WT (spectrum) = INDEFR
	IN_IM (spectrum) = NULL
	IN_IDS (spectrum) = NULL
	IN_PIX (spectrum) = NULL
end


# INIT_OUTSPEC - Initialize output spectrum structure

procedure init_outspec (spectrum)

pointer	spectrum		# spectrum structure

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("init_outspec: spec=<%d>\n")
		call pargi (spectrum)
	}

	OUT_W0 (spectrum) = INDEFR
	OUT_W1 (spectrum) = INDEFR
	OUT_WPC (spectrum) = INDEFR
	OUT_NPIX (spectrum) = INDEFI
	OUT_LOG (spectrum) = false
	OUT_PIX (spectrum) = NULL
	OUT_WTPIX (spectrum) = NULL
end


# COPY_INSPEC - Copy one input spectrum structure into another one

procedure copy_inspec (src, dest)

pointer	src, dest	# source and destination structures

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("copy_inspec: src=<%d> dest=<%d>\n")
		call pargi (src)
		call pargi (dest)
	}

	# Allocate memory for pixels
	if (IN_NPIX (dest) == INDEFI || IN_PIX (dest) == NULL)
	    call malloc (IN_PIX (dest), IN_NPIX (src), TY_REAL)
	else if (IN_NPIX (src) > IN_NPIX (dest))
	    call realloc (IN_PIX (dest), IN_NPIX (src), TY_REAL)

	# Copy pixels
	if (IN_PIX (src) != NULL)
	    call amovr (Memr[IN_PIX (src)], Memr[IN_PIX (dest)], IN_NPIX (src))

	# Copy data
	IN_W0 (dest) = IN_W0 (src)
	IN_W1 (dest) = IN_W1 (src)
	IN_WPC (dest) = IN_WPC (src)
	IN_NPIX (dest) = IN_NPIX (src)
	IN_WT (dest) = IN_WT (src)
	IN_IM (dest) = IN_IM (src)
	IN_IDS (dest) = IN_IDS (src)
end


# COPY_OUTSPEC - Copy one output spectrum structure into another one

procedure copy_outspec (src, dest)

pointer	src, dest	# source and destination structures

bool	clgetb()

begin
	if (clgetb ("debug")) {
	    call eprintf ("copy_outspec: src=<%d> dest=<%d>\n")
		call pargi (src)
		call pargi (dest)
	}

	# Allocate memory for pixels
	if (OUT_NPIX (dest) == INDEFI || OUT_PIX (dest) == NULL)
	    call malloc (OUT_PIX (dest), OUT_NPIX (src), TY_REAL)
	else if (OUT_NPIX (src) > OUT_NPIX (dest))
	    call realloc (OUT_PIX (dest), OUT_NPIX (src), TY_REAL)

	# Allocate memory for weight pixels
	if (OUT_NPIX (dest) == INDEFI || OUT_WTPIX (dest) == NULL)
	    call malloc (OUT_WTPIX (dest), OUT_NPIX (src), TY_REAL)
	else if (OUT_NPIX (src) > OUT_NPIX (dest))
	    call realloc (OUT_WTPIX (dest), OUT_NPIX (src), TY_REAL)

	# Copy pixels
	if (OUT_PIX (src) != NULL)
	    call amovr (Memr[OUT_PIX (src)], Memr[OUT_PIX (dest)],
			OUT_NPIX (src))
	if (OUT_WTPIX (src) != NULL)
	    call amovr (Memr[OUT_WTPIX (src)], Memr[OUT_WTPIX (dest)],
			OUT_NPIX (src))

	# Copy data
	OUT_W0 (dest) = OUT_W0 (src)
	OUT_W1 (dest) = OUT_W1 (src)
	OUT_WPC (dest) = OUT_WPC (src)
	OUT_NPIX (dest) = OUT_NPIX (src)
	OUT_LOG (dest) = OUT_LOG (src)
end

