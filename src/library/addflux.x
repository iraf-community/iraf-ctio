# ADD_FLUX - Add up the flux in a given bandpass. This routine assumes that
# the bandpass limits are computed taking into account the center of the
# pixel correction. For instance, in order to compute the pixel boundaries
# for a bandpass starting at wavelength "w1" and ending at wavelength "w2",
# for an image having a starting wavelength "w0" and and wavelength per pixel
# "wpc", the formulae for computing "x1" and "x2" are:
#
#	x1 = (w1 - (w0 - wpc / 2.0)) / wpc = (w1 - w0) / wpc + 0.5
#	x2 = (w2 - (w0 - wpc / 2.0)) / wpc = (w2 - w0) / wpc + 0.5
#
# This routine was taken (stoled) from noao$onedspec/t_standard.x, in order
# to have the same algorithm used in the STANDARD task.

real procedure add_flux (spec, npts, x1, x2)

real	spec[ARB]		# spectrum data
int	npts			# number of points
real	x1, x2			# bandpass (pixels)

int	i1, i2, j
real	flux

begin
	# Compute integer indexes for starting,
	# and ending wavelengths
	i1  = aint(x1) + 1
	i2  = aint(x2) + 1

	# Clear flux
	flux = 0.0

	# Sum entire pixels
	for (j = i1 + 1; j <= i2 - 1; j = j + 1)
	    flux = flux + spec[j]

	# Sum partial pixels
	flux = flux + (i1 - x1) * spec[i1]
	flux = flux + (1 - (i2 - x2)) * spec[i2]

	# Return summed flux
	return (flux)
end
