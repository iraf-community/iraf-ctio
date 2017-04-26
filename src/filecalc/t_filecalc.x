include	"filecalc.h"

# Maximum number of lines in an input file
define	MAX_RANGES		10000


# T_FILECALC -- File calculator.

procedure t_filecalc ()

char	files[SZ_LINE]			# input file list
char	expressions[SZ_LINE]		# expression list
char	lines[SZ_LINE]			# line range string
char	format[SZ_LINE]			# format string
char	dummy[1]
int	ranges[3, MAX_RANGES]		# line range array
int	calctype			# calculation type
int	nranges				# number of values in the line ranges
bool	warnings			# output warnings ?
pointer	expbuf				# expression buffer

bool	clgetb()
int	clgwrd()
int	decode_ranges()
int	fc_parse()

begin
	# Get parameters
	call clgstr ("files", files, SZ_LINE)
	call clgstr ("expressions", expressions, SZ_LINE)
	call clgstr ("lines", lines, SZ_LINE)
	call clgstr ("format", format, SZ_LINE)
	calctype = clgwrd ("calctype", dummy, 1, CALC_DICT)
	warnings = clgetb ("warnings")

	# Decode line range in ascending order
	if (decode_ranges (lines, ranges, MAX_RANGES, nranges) == ERR) 
	    call error (0, "Error in line range specification")

	# Read in expression list
	call fc_readexp (expressions, expbuf)

	# Allocate the code generation buffers for the parser
	call fc_calloc ()

	# Parse expression buffer and process input files if
	# no errors were found in the expression.
	if (fc_parse (Memc[expbuf]) == OK) {

	    # Debug
	    # call fc_cdump (50)

	    # Pocess input files
	    call fc_proc (files, ranges, format, calctype, warnings)
	}

	# Free the code generation buffers
	call fc_cfree ()

	# Free memory
	call mfree (expbuf, TY_CHAR)
end
