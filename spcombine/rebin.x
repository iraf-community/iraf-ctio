include	"spcombine.h"


# RESUM -- Rebinning using a partial pixel summation technique to
# preserve the total flux.

procedure resum (pixin, pixout, invert, ncols, nlen)

real	pixin[ARB], pixout[ARB], invert[ARB]
int	ncols, nlen

int	i
real	x1, x2, xa, xb, dx

real	pixel_parts()

begin
	# Initialize
	x1 = invert [1]
	x2 = invert [2]
	dx = x2 - x1
	xa = x1 - dx/2
	xb = x1 + dx/2
	pixout[1] = pixel_parts (pixin, nlen, xa, xb)

	do i = 2, ncols {
	    x2 = invert [i]
	    dx = x2 - x1
	    x1 = x2
	    xa = xb
	    xb = x1 + dx/2

	    pixout[i] = pixel_parts (pixin, nlen, xa, xb)
	}
end

# PIXEL_PARTS -- Integrate over partial pixels to obtain total flux
# over specified region.

real procedure pixel_parts (y, n, xa, xb)

int	n
real	y[n], xa, xb

int	i, i1, i2
real	x1, x2, cx1, cx2, frac1, frac2, sum

begin
	# Remember that pixel centers occur at integral values
	# so a pixel extends from i-0.5 to i+0.5

	x1 = max (0.5, min (xa, xb))
	x2 = min (n + 0.5, max (xa, xb))
	if (x1 >= x2)
	    return (0.)

	cx1 = x1 - 0.5
	cx2 = x2 - 0.5

	i1 = int (cx1) + 1
	i2 = int (cx2) + 1

	if (i1 == i2) {
	    frac1 = x2 - x1
	    frac2 = 0.0
	} else {
	    frac1 = int (cx1) + 1.0 - cx1
	    frac2 = cx2 - int(cx2)
	}

	sum = frac1 * y[i1]  +  frac2 * y[i2]

	# Include inclusive whole pixels
	do i = i1+1, i2-1
	    sum = sum + y[i]

	return (sum)
end

# REINTERP -- Rebin the vector by interpolation
#
# This requires a little care to propagate bad pixels and to avoid
# interpolations in which the inversion point is essentially a pixel
# position except for very small errors.  A zero input value is assumed
# to be a bad point.  Any interpolation using a bad point is set to be
# a bad point.  The use of the image interpolator may be questionable
# in the case of bad points since there may be ringing even away from
# the zero value point.

procedure reinterp (pixin, pixout, invert, ncols, nlen, mode)

real	pixin[ARB], pixout[ARB], invert[ARB]
int	ncols, nlen, mode

int	j, ipos
real	xpos

real	arieval()

begin
	do j = 1, ncols {
	    xpos = invert[j]
	    ipos = xpos
	    if (ipos < 1 || ipos > nlen)
		pixout[j] = 0.0
	    else if (abs (xpos - ipos) < RB_MINDIST)
		pixout[j] = pixin[ipos]
	    else if (pixin[ipos] == 0.0)
		pixout[j] = 0.0
	    else if (ipos < nlen && pixin[ipos+1] == 0.0)
		pixout[j] = 0.0
	    else
		pixout[j] = arieval (xpos, pixin, nlen, mode)
	}
end
