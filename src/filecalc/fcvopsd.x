# FC_VMIN[RD] -- Evaluate the minimum value of an array. It is assumed
# that the number of points in the array is always greater than zero.

double procedure fc_vmind (a, npts)

double	a[npts]			# input array
int	npts			# number of points

int	i
double	result

begin
	result = a[1]
	do i = 2, npts
	    result = min (result, a[i])
	return (result)
end


# FC_VMAX[RD] -- Evaluate the maximum value of an array. It is assumed
# that the number of points in the array is always greater than zero.

double procedure fc_vmaxd (a, npts)

double	a[npts]			# input array
int	npts			# number of points

int	i
double	result

begin
	result = a[1]
	do i = 2, npts
	    result = max (result, a[i])
	return (result)
end


# FC_VAVG[RD] -- Evaluate the average of an array. It is assumed that the
# number of points in the array is always greater than zero.

double procedure fc_vavgd (a, npts)

double	a[npts]			# input array
int	npts			# number of points

int	i
double	sum

begin
	sum = 0.0
	do i = 1, npts
	    sum = sum + a[i]
	return (sum / npts)
end


# FC_VMEDIAN[RD] -- Evaluate the median of an array. It is assumed that the
# number of points in the array is always greater than zero.

double procedure fc_vmedd (a, npts)

double	a[npts]			# input array
int	npts			# number of points

begin
	if (mod (npts, 2) == 0)
	    return (a[int (npts / 2)])
	else
	    return (a[int (npts / 2) + 1])
end


# FC_VMODE[RD] -- Evaluate the mode of an array. It is assumed that the
# number of points in the array is always greater than zero.

double procedure fc_vmoded (a, npts, nhist)

double	a[npts]			# input array
int	npts			# number of points
int	nhist			# number of histograms

double	result

begin
	result = INDEFD
	return (result)
end


# FC_VSIGMA[RD] -- Evaluate the standard deviation of an array. It is assumed
# that the number of points in the array is always greater than zero.

double procedure fc_vsigmad (a, npts)

double	a[npts]			# input array
int	npts			# number of points

int	i
double	sum, sumsq

begin
	sum   = 0.0
	sumsq = 0.0

	do i = 1, npts {
	    sum = sum + a[i]
	    sumsq = sumsq + a[i] * a[i]
	}

	sum   = sum   / npts
	sumsq = sumsq / npts

	return (sqrt (sumsq - sum * sum))
end
