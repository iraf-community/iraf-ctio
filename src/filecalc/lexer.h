# Lexer structure lengths
define	LEN_ID		256			# string length
define	LEN_CODE	256			# code length
define	LEN_LEX		(6+LEN_ID+LEN_CODE)	# total structure length

# Lexer structure
define	LEX_DVAL	Memd[P2D($1+0)]		# double value
define	LEX_RVAL	Memr[    $1+2 ]		# real value
define	LEX_IVAL	Memi[    $1+3 ]		# integer value
define	LEX_TOK		Memi[    $1+4 ]		# token
define	LEX_CLEN	Memi[    $1+5 ]		# code length
define	LEX_ID		Memc[P2C($1+6)]		# string value
define	LEX_CODE	($1+LEN_ID+6)		# start of RPN code buffer


# Keywords
define	KEYWORDS	"|at|\
			 |pi|twopi|fourpi|halfpi|\
			 |acos|asin|atan|atan2|\
			 |cos|sin|tan|\
			 |exp|log|log10|sqrt|\
			 |abs|int|\
			 |min|max|\
			 |avg|median|mode|sigma|\
			 |str|"

# Keyword codes
define	KEY_FILE		1	# file reference ("at")
	# newline		2
define	KEY_PI			3	# 3.1415926535897932385
define	KEY_TWOPI		4	# 6.2831853071795864769
define	KEY_FOURPI		5	# 12.566370614359172953
define	KEY_HALFPI		6	# 1.5707963267948966192
	# newline		7
define	K_ACOS			8	# arccosine
define	K_ASIN			9	# arcsine
define	K_ATAN			10	# arctangent
define	K_ATAN2			11	# arctangent of y / x
	# newline		12
define	K_COS			13	# cosine
define	K_SIN			14	# sine
define	K_TAN			15	# tangent
	# newline		16
define	K_EXP			17	# sine
define	K_LOG			18	# natural logarithm
define	K_LOG10			19	# decimal logarithm
define	K_SQRT			20	# square root
	# newline		21
define	K_ABS			22	# absolute value
define	K_INT			23	# integer part
	# newline		24
define	K_MIN			25	# minimum value
define	K_MAX			26	# maximum value
	# newline		27
define	K_AVG			28	# average
define	K_MEDIAN		29	# median
define	K_MODE			30	# mode
define	K_SIGMA			31	# standard deviation
	# newline		32
define	K_STR			33	# convert to string
