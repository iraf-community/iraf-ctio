# Evaluator codes. These codes are the only ones recognized by the
# run-time expression evaluator, during the evaluation of the RPN
# code generated by the parser.

# End of code marker
define	PEV_EOC		(-1)

# Numbers
define	PEV_INUMBER	0		# integer value
define	PEV_RNUMBER	1		# real value
define	PEV_DNUMBER	2		# double value
define	PEV_STRING	3		# string value

# Column
define	PEV_COLUMN	10		# column reference

# Unary operators
define	PEV_UPLUS	20		# unary plus
define	PEV_UMINUS	21		# unary minus

# Binary operators
define	PEV_PLUS	30		# addition
define	PEV_MINUS	31		# substraction
define	PEV_STAR	32		# multiplication
define	PEV_SLASH	33		# division
define	PEV_EXPON	34		# exponentiation
define	PEV_CONCAT	35		# string concatenation

# Functions
define	PEV_ACOS	40		# arc cosine
define	PEV_ASIN	41		# arc sine
define	PEV_ATAN	42		# arc tangent
define	PEV_ATAN2	43		# arc tangent of y/x

define	PEV_COS		50		# cosine
define	PEV_SIN		51		# sine
define	PEV_TAN		52		# tangent

define	PEV_EXP		60		# exponential
define	PEV_LOG		61		# natural logarithm
define	PEV_LOG10	62		# decimal logarithm
define	PEV_SQRT	63		# square root

define	PEV_ABS		70		# absolute value
define	PEV_INT		71		# integer part

define	PEV_MIN		80		# minimum value
define	PEV_MAX		81		# maximum value

define	PEV_AVG		90		# average
define	PEV_MEDIAN	91		# median
define	PEV_MODE	92		# mode
define	PEV_SIGMA	93		# standard deviation

define	PEV_COLMIN	100		# column minimum value
define	PEV_COLMAX	101		# column maximum value

define	PEV_COLAVG	120		# column average
define	PEV_COLMEDIAN	121		# column median
define	PEV_COLMODE	122		# column mode
define	PEV_COLSIGMA	123		# column standard deviation

define	PEV_STR		130		# convert to string