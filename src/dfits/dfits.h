# FITS Definitions

# The FITS standard readable by the FITS displayer using these definitions:
# 
# 1.  8 bits / byte
# 2.  ASCII character code
# 3.  MII data format (i.e. 8 bit unsigned integers and 16 and 32 bit signed
#     twos complement integers with most significant bytes first.)
#     See mii.h.
#
# The following deviations from the FITS standard are allowed:
# 
# The number of FITS bytes per record is normally 2880 but may be specified
# by the user.


# Define the bits per pixel of the 3 basic FITS types

define	FITS_BYTE	8	# Bits in a FITS byte (used)
#define	FITS_SHORT	16	# Bits in a FITS short (not used)
#define	FITS_LONG	32	# Bits in a FITS long (not used)


# Define other misc.

define	LSBF		NO	# Least significant byte first
define	LEN_CARD	80	# Length of FITS card in characters
define	COL_VALUE	11	# Starting column for parameter values


# Define size of tables in memory

define	MAX_TABLE	30	# number of keywords and formats
define	MAX_CARDS	100	# number of cards


# Define sizes of keywords and formats

define	SZ_KEYWORD	8	# length of keywords in characters
define	SZ_FORMAT	8	# length of formats in characters (%-dd.ddc)


# Define test of formats

define	IS_STRING	($1 == 's')
define	IS_INTEGER	($1 == 'd' || $1 == 'o' || $1 == 'x')
define	IS_FLOAT	(($1 >= 'e' && $1 <= 'h') || $1 == 'm')
define	IS_FORMAT	(IS_STRING($1) || IS_INTEGER($1) || IS_FLOAT($1))

# Define possible formats

define	FORMAT_DICT	"defghmosx"
