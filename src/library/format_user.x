# USERPROC -- User supplied procedure template for fm_fprintf().

procedure userproc (dtype, bval, cval, lval, dval, xval, strval, maxch, ptr)

int	dtype			# data type requested
bool	bval			# boolean value (output)
char	cval			# character value (output)
long	lval			# integer/long value (output)
double	dval			# real/double value (output)
complex	xval			# complex value (output)
char	strval[maxch]		# string value (output)
int	maxch			# max number of characters in string value
pointer	ptr			# pointer to user defined structure

begin
	# Branch on data type
	switch (dtype) {
	case TY_BOOL:
	case TY_CHAR:
	    # Decide whether a single character or a
	    # character string is needed
	    if (maxch == 0) {
	    } else {
	    }
	case TY_LONG:
	case TY_DOUBLE:
	case TY_COMPLEX:
	default:
	}
end
