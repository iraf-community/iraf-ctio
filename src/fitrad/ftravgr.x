include	"fitrad.h"

# Number of segments to compute the histogram when using the mode
define	NHIST		100


# FTR_AVERAGE -- Average data points by using the mean, median, or mode
# of the data. The output is placed in the first locations of the input
# arrays to minimize memory allocation. The total input number of points
# is redefined to be the output number of points.

procedure ftr_averager (x, y, npts, minwidth, minpts, ringavg)

real	x[npts]			# x data (in/out)
real	y[npts]			# y data (in/out)
int	npts			# number of points (in/out)
real	minwidth		# minimum ring width
int	minpts			# minimum number of points
int	ringavg			# averaging mode

bool	dynamic
int	i, ip, op, n
int	nring, ninter
real	width, maxwidth
real	aux

begin
	# Return if no averaging was selected
	if (ringavg == RGV_NONE)
	    return

	# Copy parameters into local variables to
	# avoid modifying them for the next call
	width = minwidth
	nring = minpts

	# Constrain the the number of points in a ring
	if (!IS_INDEFI (nring))
	    nring = max (1, min (nring, npts))

	# Decide wether to divide the whole range into rings
	# of constant number of points, or constant width.
	if (IS_INDEFR (width)) {

	    # Set the number of rings in which the total
	    # interval is divided
	    ninter = npts / nring

	    # Set flag for average computing
	    dynamic = false

	} else {

	    # Constrain the width to appropiate limits
	    maxwidth = x[npts] - x[1]
	    width = max (maxwidth / 1000, min (width, maxwidth))

	    # Compute the number of intervals in which the maximum width
	    # is divided, and, using this number, recompute the width
	    # to be an integral part of the maximum width
	    ninter = max (1, int (maxwidth / width))
	    width  = maxwidth / ninter

	    # Loop counting the number of points in the first interval
	    # (the shortest one), increasing the width, until the number
	    # of points in the ring is greater than the minimum number
	    # required.
	    repeat {
		aux = x[1] + width
		for (n = 1; x[n] < aux; n = n + 1)
		    ;
		n = n - 1

		if (IS_INDEFI (nring)) {
		    nring = n
		    break
		}

		if (n < nring) {
		    ninter = ninter - 1
		    width = maxwidth / ninter
		} else
		    break
	    }

	    # Set flag for average computing
	    dynamic = true
	}

	# Loop averaging the points in each ring and storing these
	# averages back into the input arrays, overwritting data
	# that was used already to compute averages.
	ip = 1
	op = 1
	do n = 1, ninter {

	    # Recompute number of points for each ring
	    if (dynamic) {
		aux = x[1] + n * width
		for (i = ip; x[i] < aux && i <= npts; i = i + 1)
		    ;
		nring = i - ip
	    }

	    # Compute average for the ring
	    switch (ringavg) {
	    case RGV_MEAN:
	        call ftr_meanr (x[ip], y[ip], nring, x[op], y[op])
	    case RGV_MEDIAN:
		call ftr_zmedianr (x[ip], y[ip], nring, x[op], y[op])
	    case RGV_MODE:
		call ftr_moder (x[ip], y[ip], nring, x[op], y[op])
	    default:
		call error (0, "Unknown ring averaging mode (ftr_average)")
	    }

	    # Update for next iteration
	    ip = ip + nring
	    op = op + 1
	}

	# Update number of data points
	npts = op - 1
end


# FTR_MEAN -- Compute the mean of the y data

procedure ftr_meanr (x, y, npts, xavg, yavg)

real	x[npts]			# x data
real	y[npts]			# y data
int	npts			# number of points
real	xavg			# x point for average
real	yavg			# y avrage

int	i
real	dummy

int	awvgr()

begin
	xavg = (x[1] + x[npts]) / 2
	i = awvgr (y, npts, yavg, dummy, 0.0, 0.0)
end


# FTR_ZMEDIAN -- Compute the median of the y data

procedure ftr_zmedianr (x, y, npts, xavg, yavg)

real	x[npts]			# x data
real	y[npts]			# y data
int	npts			# number of points
real	xavg			# x point for average
real	yavg			# y avrage

int	i1, i2

begin
	i1 = npts / 2
	i2 = i1 + 1

	if (mod (npts, 2) == 0) {
	    xavg = (x[i1] + x[i2]) / 2
	    yavg = (y[i1] + y[i2]) / 2
	} else {
	    xavg = x[i2]
	    yavg = y[i2]
	}
end


# FTR_MODE -- Compute the mode of the y data

procedure ftr_moder (x, y, npts, xavg, yavg)

real	x[npts]			# x data
real	y[npts]			# y data
int	npts			# number of points
real	xavg			# x point for average
real	yavg			# y average

int	hist[NHIST], i, n, nmax, hmax
real	mean[NHIST], minval, maxval, delta

begin
	# Compute minimum and maximum values in the y data,
	# and determine the increment between each segment
	call alimr (y, npts, minval, maxval)

	# If minimum and maximum are equal that means
	# either that there is only only one point,
	# or that there is only one value for all points.
	if (maxval == minval) {
	    xavg = x[1]
	    yavg = y[1]
	    return
	}

	# Initialize histogram and averages
	call aclri (hist, NHIST)
	call aclrr (mean, NHIST)

	# Build the histogram
	delta = (maxval - minval) / NHIST
	do i = 1, npts {
	    n = max (1, min (int ((y[i] - minval) / delta + 1), NHIST))
	    hist[n] = hist[n] + 1
	    mean[n] = mean[n] + y[i]
	}

	# Find the maximum value of the histogram, and
	# its corresponding index
	nmax = 1
	hmax = hist[nmax]
	do i = 1, NHIST {
	    if (hist[i] > hmax) {
		nmax = i
		hmax = hist[nmax]
	    }
	}

	# Compute mode
	xavg = (x[1] + x[npts]) / 2
	yavg = mean[nmax] / hmax
end
