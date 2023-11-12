.help fft1d Jan90
One Dimensional Fast Fourier Transform

These procedures handle calls to the standard VOPS FFT procedures. There
are four possible VOPS routines that can be called, depending on the 
transformation type (real, complex), and the direction (forward, inverse).
These choices are summarized in the following table:
.nf

 procedure   |  input	  |  output	|  type       |  direction
-------------+------------+-------------+-------------+-------------
 aiftrx	     |  complex	  |  real	|  real	      |  inverse
 afftrx	     |  real	  |  complex	|  real	      |  forward
 aiftxx	     |  complex	  |  complex	|  complex    |  inverse
 afftxx	     |  complex   |  complex	|  complex    |  forward

.fi
The \fBfft1_init\fR procedure sets the transformation type and the
direction, by using two boolean parameters for real and inverse
transformation, respectively. Buffers for input and output data are
allocated acording to the data types defined above. The initial size
of the data buffers can be defined as well. The buffer are free by
calling the \fBfft1_free\fR procedure. The \fBfft_clear\fR procedure
is used when one wants to restart from fresh, but without the overhead
of freeing the buffers.
.sp
Data can be entered sequentially into the input buffer by using the
\fBfft1_put\fR procedure. The size of both buffers is increased dynamically
if necessary.
.sp
Data can be retrieved sequentially from the output (transfomed) buffer by
using the the \fBfft1_get\fR procedure. Reading can be restarted from the
beginning with the \fBfft_rew\fR procedure.
.sp
The actual size of the transformation buffers can be retrieved using the
\fBfft_size\fR procedure. The number returned will be always a power of
two.
.sp
The actual transformation is performed by the \fBfft1_fft\fR procedure.
This procedure takes the data from the input buffer, and places its
transformation into the output buffer. The input data is left unchanged.
.nf

Entry points:

	  fft1_init  (fft, size, tyreal, inverse, flip) Initialize fft struc.
	  fft1_clear (fft)				Clear FFT structure
	  fft1_free  (fft)				Free fft structure

	  fft1_put (fft, xr, xi)		Put value into buffer

    int = fft1_get (fft, xr, xi)		Get value from buffer
	  fft1_rew (fft)			Rewind fft1_get counter

    int = fft1_size (fft)			Return buffer size

	  fft1_fft (fft)			Take transformation

Low level entry point:

	  fft1_realloc (fft)			Reallocate fft buffers
	  fft1_chk (fft, label)			Check fft descriptor
 	  fft1_dump (fft, label)		Dump fft structure (debug)
.fi
.endhelp

# Magic number value
define	MAGIC_NUMBER		1990

# Pointer Mem
define	MEMP			Memi

# Buffer structure
define	LEN_FFT1		9		# structure length
define	FFT1_MAGIC		Memi[$1+0]	# magic number
define	FFT1_BUFIN		MEMP[$1+1]	# pointer to input buffer
define	FFT1_BUFOUT		MEMP[$1+2]	# pointer to output buffer
define	FFT1_SIZE		Memi[$1+3]	# buffer sizes
define	FFT1_TYREAL		Memb[$1+4]	# real transformation ?
define	FFT1_INVERSE		Memb[$1+5]	# inverse transformation ?
define	FFT1_FLIP		Memb[$1+6]	# flip negative/positive parts ?
define	FFT1_NGET		Memi[$1+7]	# get counter
define	FFT1_NPUT		Memi[$1+8]	# put counter


# FFT1_INIT -- Initialize FFT structure

procedure fft1_init (fft, size, tyreal, inverse, flip)

pointer	fft			# FFT descriptor
int	size			# Initial size
bool	tyreal			# real transformation ?
bool	inverse			# inverse transformation ?
bool	flip			# flip negative and positive parts ?

int	newsize

begin
	# Use the next power of two as size
	newsize = 1
	while (newsize < size)
	    newsize = newsize + newsize
	    
	# Allocate and initialize strucure
	call malloc  (fft, LEN_FFT1, TY_STRUCT)
	FFT1_MAGIC   (fft) = MAGIC_NUMBER
	FFT1_BUFIN   (fft) = NULL
	FFT1_BUFOUT  (fft) = NULL
	FFT1_SIZE    (fft) = newsize
	FFT1_TYREAL  (fft) = tyreal
	FFT1_INVERSE (fft) = inverse
	FFT1_FLIP    (fft) = flip
	FFT1_NPUT    (fft) = 0
	FFT1_NGET    (fft) = 1

	# Allocate data space
	if (tyreal) {
	    if (inverse) {
		call calloc (FFT1_BUFIN  (fft), newsize, TY_COMPLEX)
		call calloc (FFT1_BUFOUT (fft), newsize, TY_REAL)
	    } else {
		call calloc (FFT1_BUFIN  (fft), newsize, TY_REAL)
		call calloc (FFT1_BUFOUT (fft), newsize, TY_COMPLEX)
	    }
	} else {
	    call calloc (FFT1_BUFIN  (fft), newsize, TY_COMPLEX)
	    call calloc (FFT1_BUFOUT (fft), newsize, TY_COMPLEX)
	}
end


# FFT1_REALLOC -- Reallocate transformation buffers

procedure fft1_realloc (fft)

pointer	fft			# FFT descriptor

int	size, newsize

begin
	# Pull old size from structure
	size = FFT1_SIZE (fft)

	# Reallocate buffer space
	newsize = size * 2
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft)) {
		call realloc (FFT1_BUFIN  (fft), newsize, TY_COMPLEX)
		call realloc (FFT1_BUFOUT (fft), newsize, TY_REAL)
		call aclrx (Memx[FFT1_BUFIN  (fft) + size], newsize - size)
		call aclrr (Memr[FFT1_BUFOUT (fft) + size], newsize - size)
	    } else {
		call realloc (FFT1_BUFIN  (fft), newsize, TY_REAL)
		call realloc (FFT1_BUFOUT (fft), newsize, TY_COMPLEX)
		call aclrr (Memr[FFT1_BUFIN  (fft) + size], newsize - size)
		call aclrx (Memx[FFT1_BUFOUT (fft) + size], newsize - size)
	    }
	} else {
	    call realloc (FFT1_BUFIN  (fft), newsize, TY_COMPLEX)
	    call realloc (FFT1_BUFOUT (fft), newsize, TY_COMPLEX)
	    call aclrx (Memx[FFT1_BUFIN  (fft) + size], newsize - size)
	    call aclrx (Memx[FFT1_BUFOUT (fft) + size], newsize - size)
	}

	# Update structure
	FFT1_SIZE (fft) = newsize
end


# FFT1_CLEAR -- Clear FFT structure without freeing buffers.

procedure fft1_clear (fft)

pointer	fft			# FFT descriptor

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_clear")

	# Clear counters
	FFT1_NPUT (fft) = 0
	FFT1_NGET (fft) = 1

	# Clear buffers
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft)) {
		call aclrx (Memx[FFT1_BUFIN  (fft)], FFT1_SIZE (fft))
		call aclrr (Memr[FFT1_BUFOUT (fft)], FFT1_SIZE (fft))
	    } else {
		call aclrr (Memr[FFT1_BUFIN  (fft)], FFT1_SIZE (fft))
		call aclrx (Memx[FFT1_BUFOUT (fft)], FFT1_SIZE (fft))
	    }
	} else {
	    call aclrx (Memx[FFT1_BUFIN  (fft)], FFT1_SIZE (fft))
	    call aclrx (Memx[FFT1_BUFOUT (fft)], FFT1_SIZE (fft))
	}
end


# FFT1_FREE -- Free transformation buffers

procedure fft1_free (fft)

pointer	fft			# FFT descriptor

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_free")

	# Free buffer space
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft)) {
		call mfree (FFT1_BUFIN (fft), TY_COMPLEX)
		call mfree (FFT1_BUFOUT (fft), TY_REAL)
	    } else {
		call mfree (FFT1_BUFIN (fft), TY_REAL)
		call mfree (FFT1_BUFOUT (fft), TY_COMPLEX)
	    }
	} else {
	    call mfree (FFT1_BUFIN (fft), TY_COMPLEX)
	    call mfree (FFT1_BUFOUT (fft), TY_COMPLEX)
	}
	call mfree (fft, TY_STRUCT)
end


# FFT1_REW -- Rewind get counter

procedure fft1_rew (fft)

pointer	fft			# FFT descriptor

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_rew")

	# Reset get counter
	FFT1_NGET (fft) = 1
end


# FFT1_GET -- Get data from output buffer.

int procedure fft1_get (fft, xr, xi)

pointer	fft			# FFT descriptor
real	xr, xi			# returned data

int	n

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_get")

	# Check if there is more data
	if (FFT1_NGET (fft) > FFT1_SIZE (fft))
	    return (EOF)

	# Convert get counter into buffer index
	if (FFT1_FLIP (fft)) {
	    if (FFT1_NGET (fft) < FFT1_SIZE (fft) / 2)
		n = FFT1_SIZE (fft) / 2 + FFT1_NGET (fft)
	    else
		n = FFT1_NGET (fft) - FFT1_SIZE (fft) / 2
	} else
	    n = FFT1_NGET (fft) - 1

	# Get data from output buffer
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft)) {
		xr = Memr[FFT1_BUFOUT (fft) + n]
		xi = 0.0
	    } else {
		xr = real  (Memx[FFT1_BUFOUT (fft) + n])
		xi = aimag (Memx[FFT1_BUFOUT (fft) + n])
	    }
	} else {
	    xr = real  (Memx[FFT1_BUFOUT (fft) + n])
	    xi = aimag (Memx[FFT1_BUFOUT (fft) + n])
	}

	# Count data points and return
	FFT1_NGET (fft) = FFT1_NGET (fft) + 1
	return (OK)
end


# FFT1_PUT -- Put data into input buffer. Reallocate buffers if necessary

procedure fft1_put (fft, xr, xi)

pointer	fft			# FFT descriptor
real	xr, xi			# data to enter

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_put")

	# Reallocate buffers if the number of points is greater
	# than the buffer sizes
	if (FFT1_NPUT (fft) >= FFT1_SIZE (fft))
	    call fft1_realloc (fft)

	# Count data points
	FFT1_NPUT (fft) = FFT1_NPUT (fft) + 1

	# Enter data into input buffer
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft))
		Memx[FFT1_BUFIN (fft) + FFT1_NPUT (fft) - 1] = complex (xr, xi)
	    else
		Memr[FFT1_BUFIN (fft) + FFT1_NPUT (fft) - 1] = xr
	} else
	    Memx[FFT1_BUFIN (fft) + FFT1_NPUT (fft) - 1] = complex (xr, xi)
end


# FFT1_SIZE -- Return buffer size used in the transformation. This number
# is always a power of two.

int procedure fft1_size (fft)

pointer	fft			# FFT descriptor

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_size")

	# Return buffer size
	return (FFT1_SIZE (fft))
end


# FFT1_FFT -- Take the FFT of input buffer

procedure fft1_fft (fft)

pointer	fft			# FFT descriptor

errchk	fft1_chk()

begin
	# Check fft descriptor
	call fft1_chk (fft, "fft1_fft")

	# Perform selected type of transformation
	if (FFT1_TYREAL (fft)) {
	    if (FFT1_INVERSE (fft))
		call aiftrx (Memx[FFT1_BUFIN (fft)], Memr[FFT1_BUFOUT (fft)],
			     FFT1_SIZE (fft))
	    else
		call afftrx (Memr[FFT1_BUFIN (fft)], Memx[FFT1_BUFOUT (fft)],
			     FFT1_SIZE (fft))
	} else {
	    if (FFT1_INVERSE (fft))
		call aiftxx (Memx[FFT1_BUFIN (fft)], Memx[FFT1_BUFOUT (fft)],
			     FFT1_SIZE (fft))
	    else
		call afftxx (Memx[FFT1_BUFIN (fft)], Memx[FFT1_BUFOUT (fft)],
			     FFT1_SIZE (fft))
	}
end


# FFT1_CHK -- Check FFT descriptor.

procedure fft1_chk (fft, label)

pointer	fft			# FFT descriptor
char	label[ARB]		# error label

char	msg[SZ_LINE]

begin
	# Check for null pointer
	if (fft == NULL) {
	    call sprintf (msg, SZ_LINE, "%s: Null descriptor pointer")
		call pargstr (label)
	    call error (0, msg)
	}

	# Check for bad magic number
	if (FFT1_MAGIC (fft) != MAGIC_NUMBER) {
	    call sprintf (msg, SZ_LINE, "%s: Bad magic number")
		call pargstr (label)
	    call error (0, msg)
	}
end


# FFT1_DUMP -- Dump fft structure.

procedure fft1_dump (fft, label)

pointer	fft			# FFT descriptor
char	label[ARB]		# structure label

begin
	if (fft == NULL) {
	    call eprintf ("FFT structure (%s): Null pointer\n")
	    return
	}

	call eprintf ("FFT structure (%s):\n")
	    call pargstr (label)
	call eprintf ("  Magic number                 = %d (%d)\n")
	    call pargi (FFT1_MAGIC (fft))
	    call pargi (MAGIC_NUMBER)
	call eprintf ("  Input buffer pointer         = %d\n")
	    call pargi (FFT1_BUFIN (fft))
	call eprintf ("  Output buffer pointer        = %d\n")
	    call pargi (FFT1_BUFOUT (fft))
	call eprintf ("  Buffer size                  = %d\n")
	    call pargi (FFT1_SIZE (fft))
	call eprintf ("  Real transformation          = %b\n")
	    call pargb (FFT1_TYREAL (fft))
	call eprintf ("  Inverse transformation       = %b\n")
	    call pargb (FFT1_INVERSE (fft))
	call eprintf ("  Flip positive/negative parts = %b\n")
	    call pargb (FFT1_FLIP (fft))
	call eprintf ("  Get counter                  = %d\n")
	    call pargi (FFT1_NGET (fft))
	call eprintf ("  Put counter                  = %d\n")
	    call pargi (FFT1_NPUT (fft))
end
