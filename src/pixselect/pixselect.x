include <imhdr.h>



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselects (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
short	floor, ceil
pointer	line
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnls()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnls (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %g\n")
			call pargs (Mems[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = short (upper)
	    while (imgnls (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Mems[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargs (Mems[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    while (imgnls (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Mems[line + i - 1] >= floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargs (Mems[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    while (imgnls (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Mems[line + i - 1] >= floor &&
			Mems[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargs (Mems[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselecti (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
int	floor, ceil
pointer	line
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnli()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnli (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %g\n")
			call pargi (Memi[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = int (upper)
	    while (imgnli (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memi[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargi (Memi[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    while (imgnli (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memi[line + i - 1] >= floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargi (Memi[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    while (imgnli (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memi[line + i - 1] >= floor &&
			Memi[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargi (Memi[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselectl (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
long	floor, ceil
pointer	line
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnll()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnll (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %g\n")
			call pargl (Meml[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = long (upper)
	    while (imgnll (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Meml[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargl (Meml[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    while (imgnll (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Meml[line + i - 1] >= floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargl (Meml[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    while (imgnll (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Meml[line + i - 1] >= floor &&
			Meml[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargl (Meml[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselectr (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
real	floor, ceil
pointer	line
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnlr()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnlr (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %g\n")
			call pargr (Memr[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = real (upper)
	    while (imgnlr (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memr[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargr (Memr[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    while (imgnlr (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memr[line + i - 1] >= floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargr (Memr[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    while (imgnlr (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memr[line + i - 1] >= floor &&
			Memr[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargr (Memr[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselectd (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
double	floor, ceil
pointer	line
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnld()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnld (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %g\n")
			call pargd (Memd[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = double (upper)
	    while (imgnld (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memd[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargd (Memd[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    while (imgnld (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memd[line + i - 1] >= floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargd (Memd[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    while (imgnld (im, line, v) != EOF) {
		do i = 1, npix {
		    if (Memd[line + i - 1] >= floor &&
			Memd[line + i - 1] <= ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %g\n")
			    call pargd (Memd[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end



# PIXSELECT -- List pixels in an image between a lower and upper value.

procedure pixselectx (im, lower, upper)

pointer	im				# Image descriptor
real	lower, upper			# Range to be replaced

int	i, j
int	npix, ndim
complex	floor, ceil
pointer	line
real	abs_floor, abs_ceil
long	v[IM_MAXDIM], lv[IM_MAXDIM]

int	imgeti(), imgnlx()

begin
	# Setup start vector for sequential reads and writes.
	call amovkl (long(1), v,  IM_MAXDIM)
	call amovl  (v,       lv, IM_MAXDIM)

	# Get image dimension
	ndim = imgeti (im, "i_naxis")
	npix = imgeti (im, "i_naxis1")

	# If both lower and upper are INDEF then list all pixels, if
	# lower is INDEF then list all pixels below upper, and if upper
	# is INDEF then list all pixels above lower. Otherwise list pixels
	# in the given window.
	if (IS_INDEFR (lower) && IS_INDEFR (upper)) {
	    while (imgnlx (im, line, v) != EOF) {
		do i = 1, npix {
		    call printf (" %4d")		# x
			call pargi (i)
		    do j = 2, ndim {			# y, z, ...
		        call printf (" %4d")
			    call pargl (lv[j])
		    }
		    call printf ("  %z\n")		# pixel value
			call pargx (Memx[line + i - 1])
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (lower)) {
	    ceil = complex (upper)
	    abs_ceil = abs (ceil)
	    while (imgnlx (im, line, v) != EOF) {
		do i = 1, npix {
		    if (abs (Memx[line + i - 1]) <= abs_ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %z\n")		# pixel value
			    call pargx (Memx[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else if (IS_INDEFR (upper)) {
	    floor = double (lower)
	    abs_floor = abs (floor)
	    while (imgnlx (im, line, v) != EOF) {
		do i = 1, npix {
		    if (abs (Memx[line + i - 1]) >= abs_floor) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %z\n")		# pixel value
			    call pargx (Memx[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }

	} else {
	    floor = double (lower)
	    ceil  = double (upper)
	    abs_ceil  = abs (ceil)
	    abs_floor = abs (floor)
	    while (imgnlx (im, line, v) != EOF) {
		do i = 1, npix {
		    if (abs (Memx[line + i - 1]) >= abs_floor &&
			abs (Memx[line + i - 1]) <= abs_ceil) {
			call printf (" %4d")		# x
			    call pargi (i)
			do j = 2, ndim {		# y, z, ...
			    call printf (" %4d")
				call pargl (lv[j])
			}
			call printf ("  %z\n")		# pixel value
			    call pargx (Memx[line + i - 1])
		    }
		}
		call amovl (v, lv, IM_MAXDIM)
	    }
	}
end


