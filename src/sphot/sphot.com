# SPHOT.COM - This file contains the declaration variables handling
# hidden parameters of the sphot task.

# Parameters
int	niter			# iterations centroid
int	cside			# half with of centering box
int	isky			# sky mode (code)
real	rstar			# radius of stellar aperture
real	r1, r2			# sky radii (inner, outer)
real	rdel			# maximun shift from initial position
real	ksig			# sigma rejection parameter
real	zpoint			# magnitude zero point
real	gain			# gain (electrons/ADU)
char	skymode[SZ_LINE]	# sky mode (string)
bool	verbose			# verbose output ?

common	/sphotcom/	niter, cside, isky, rstar, r1, r2, rdel, ksig,
			zpoint, gain, skymode, verbose
