#{ Fabry-Perot Reduction Package

plot
images
tv

package	fabry

# Allocate image header space
set min_lenuserarea = 32000

task	ringpars,
	fitring,
	icntr,
	mkshift,
	mkcube,
	normalize,
	findsky,
	zeropt,
	avgvel,
	velocity	= fabry$x_fabry.e

task	fpspec		= fabry$fpspec.cl
task	intvel		= fabry$intvel.cl

clbye()
