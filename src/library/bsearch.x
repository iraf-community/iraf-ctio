include	<mach.h>



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchc (a, npts, key, lower, upper)

char	a[ARB]			# input array
int	npts			# number of points in array
char	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (key == a[lower]) {
	    upper = lower
	    return (OK);
	} else if (key == a[upper]) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchs (a, npts, key, lower, upper)

short	a[ARB]			# input array
int	npts			# number of points in array
short	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (key == a[lower]) {
	    upper = lower
	    return (OK);
	} else if (key == a[upper]) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchi (a, npts, key, lower, upper)

int	a[ARB]			# input array
int	npts			# number of points in array
int	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (key == a[lower]) {
	    upper = lower
	    return (OK);
	} else if (key == a[upper]) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchl (a, npts, key, lower, upper)

long	a[ARB]			# input array
int	npts			# number of points in array
long	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (key == a[lower]) {
	    upper = lower
	    return (OK);
	} else if (key == a[upper]) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchr (a, npts, key, lower, upper)

real	a[ARB]			# input array
int	npts			# number of points in array
real	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (abs (key - a[lower]) < EPSILONR) {
	    upper = lower
	    return (OK);
	} else if (abs (key - a[upper]) < EPSILONR) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end



# BSEARCH -- Binary search over an increasing ordered array. If the key is
# found the procedure returns OK, and the upper and lower limits have the
# same value. Otherwise it returns ERR, and the lower and upper limits
# delimit the range where the key would be located. When the key is less
# than the first element in the array the lower limit is zero, and when is
# greater than the last element the upper limit is the number of points in
# the array plus one.

int procedure bsearchd (a, npts, key, lower, upper)

double	a[ARB]			# input array
int	npts			# number of points in array
double	key			# quantity to search for
int	lower, upper		# lower and upper indices (output)

int	k

begin	       
	# Return inmediately if the key is out of bounds.
	# Otherwise set up limits to start the iteration.
	if (key < a[1]) {
	    lower = 0
	    upper = 1
	    return (ERR);
	} else if (key > a[npts]) {
	    lower = npts
	    upper = npts + 1
	    return (ERR);
	} else {
	    lower = 1
	    upper = npts
	}

	# Look for the upper and lower limits
	while (upper - lower > 1) {
	    k = int ((lower + upper) / 2)
	    if (key > a[k])
	        lower = k
	    else
	        upper = k
	}

	# Check for equality
	if (abs (key - a[lower]) < EPSILOND) {
	    upper = lower
	    return (OK);
	} else if (abs (key - a[upper]) < EPSILOND) {
	    lower = upper
	    return (OK);
	} else
	    return (ERR);
end


