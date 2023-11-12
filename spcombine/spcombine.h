# Help key file and prompt
define	KEY	"ctio$lib/scr/spcombine.key"
define	PROMPT	"spcombine options"

# Interpolation modes for rebinning
define	INTERP_MODE	"|linear|spline3|poly3|poly5|sums|"
define	RB_LINEAR	1
define	RB_SPLINE3	2
define	RB_POLY3	3
define	RB_POLY5	4
define	RB_SUMS		5

# Weighting options
define	WT_TYPE		"|none|expo|user|"
define	WT_NONE		1
define	WT_EXPO		2
define	WT_USER		3

# Sorting modes
define	SORT_MODE	"|none|increasing|decreasing|"
define	SORT_NONE	1
define	SORT_INC	2
define	SORT_DEC	3

# Blank pixel value
define	BAD_PIX		0.0

# If the interpolation is less than this distance from a input point then
# don't interpolate.
define	RB_MINDIST	0.001

# Maximum number of spectra to combine
define	MAX_NR_SPECTRA	100

# Combining modes in interactive mode
define	COMB_AGAIN	0
define	COMB_BLIND	1
define	COMB_FIRST	2
define	COMB_NEXT	3
define	COMB_SKIP	4

# Pointer data
define	MEMP		Memi

# Structure for each of the input spectra
define	LEN_IN		8
define	IN_W0		Memr[P2R($1+0)]	# rebinned starting wavelength
define	IN_W1		Memr[P2R($1+1)]	# rebinned ending wavelength
define	IN_WPC		Memr[P2R($1+2)]	# rebinned wavelength increment
define	IN_NPIX		Memi[$1+3]	# rebinned spectrum length
define	IN_WT		Memr[P2R($1+4)]	# weighting factor
define	IN_IM		MEMP[$1+5]	# image descriptor
define	IN_IDS		MEMP[$1+6]	# ids header
define	IN_PIX		MEMP[$1+7]	# rebinned pixels

# Structure for output spectrum
define	LEN_OUT		9
define	OUT_W0		Memr[P2R($1+0)]	# Starting wavelength
define	OUT_W1		Memr[P2R($1+1)]	# ending wavelength
define	OUT_WPC		Memr[P2R($1+2)]	# wavelength increment
define	OUT_NPIX	Memi[$1+3]	# spectrrum length
define	OUT_LOG		Memb[$1+4]	# log scale ?
define	OUT_PIX		MEMP[$1+7]	# spectrum pixels
define	OUT_WTPIX	MEMP[$1+8]	# weighting spectrum pixels

# Macros to evaluate the index in the pixel array as a function
# of the wavelength, for an input and output spectrum

define	IN_INDEX	(int (($2 - IN_W0 ($1)) / IN_WPC ($1) + 0.5) + 1)
define	OUT_INDEX	(int (($2 - OUT_W0 ($1)) / OUT_WPC ($1) + 0.5) + 1)

# Macros to evaluate the wavelength in the spectrum as a function
# of the index, for the input and output spectrum

define	IN_WAVE		(IN_W0 ($1) + ($2 - 1) * IN_WPC ($1))
define	OUT_WAVE	(OUT_W0 ($1) + ($2 - 1) * OUT_WPC ($1))
