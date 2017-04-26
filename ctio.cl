#{ Package script task for the CTIO package.  Add task declarations here
# for any CTIO tasks or subpackages.

cl < "ctio$lib/zzsetenv.def"

package ctio, bin=ctiobin$


# Definitions

set	compression	= "ctio$compression/"
set	fabry		= "ctio$fabry/"
set	manuals		= "ctio$manuals/"

# Apropos database. This environment variable is used by the apropos task.
# It should have one entry per external package, but the total string length
# shouldn't exceed SZ_APROPOSDB (defined in ctio$src/t_apropos.x).

set	aproposdb	= "ctio$src/apropos/db/root.db\
			  ,ctio$src/apropos/db/noao.db\
			  ,ctio$src/apropos/db/ctio.db\
			  ,ctio$src/apropos/db/stsdas.db\
			  "

# Subpackages

task	compression.pkg	= "compression$compression.cl"
task	fabry.pkg	= "fabry$fabry.cl"


# CL scripts

task	fixtail		= "ctio$fixtail/fixtail.cl"
task	focus		= "ctio$focus/focus.cl"
task	growthcurve	= "ctio$growthcurve/growthcurve.cl"
task	imextract	= "ctio$imextract/imextract.cl"
task	midut		= "ctio$midut/midut.cl"


# SPP tasks

task	apropos,
	bin2iraf,
	bitstat,
	chpixfile,
	colselect,
	compairmass,
	coords,
	cureval,
	dfits,
	eqwidths,
	fft1d,
	filecalc,
	findfiles,
	fitrad,
	helio,
	gki2cad,
	imcreate,
	immatch,
	imsort,
	imspace,
	imtest,
	iraf2bin,
	irlincor,
	lambda,
	magavg,
	magband,
	mapkeyword,
	mjoin,
	mkapropos,
	pixselect,
	sphot,
	statspec,
	wairmass	= "ctio$x_ctio.e"

task	spcombine	= "ctio$spcombine/x_spcombine.e"

clbye()
