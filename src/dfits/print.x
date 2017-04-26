include	"dfits.h"

# PRINT_STRING - Print a quantity as a number or string of characters.
# It first tries to print the quantity with the format code specified
# i.e, string, integer, real or double precission, using the format
# specified. If it fails, it prints the quantity as a string.
# The format is a string of the the form "%W.D" where "W" sets the field
# width and "D" the number of characters or digits to print. It is almost
# an FMTIO specification, except by the format code.
# The format code is the equivalent of the "C" part of an FMTIO format.
# It takes three possible values: "s" for strings, "d" for integers or
# long integers, and "f" for real or double precission numbers.

procedure print_string (str, format, code)

char	str[ARB]		# string to print
char	format[ARB]		# format to use
char	code			# format code

char	fmtstr[SZ_LINE]
int	ip
long	lval
real	rval
double	dval

int	ctol(), ctor(), ctod()

begin
	# Build up format string
	call sprintf (fmtstr, SZ_LINE, "%s%c ")
	    call pargstr (format)
	    call pargc (code)


	# Print according the format specified
	ip = 1
	if (IS_STRING(code)) {
	    call printf (fmtstr)
		call pargstr (str)
	} else if (IS_INTEGER(code)) {
	    if (ctol (str, ip, lval) > 0) {
	        call printf (fmtstr)
		    call pargl (lval)
	    } else {
		call sprintf (fmtstr, SZ_LINE, "%ss ")
	    	    call pargstr (format)
		call printf (fmtstr)
		    call pargstr (str)
	    }
	} else if (IS_FLOAT(code)) {
	    if (ctor (str, ip, rval) > 0) {
		call printf (fmtstr)
		    call pargr (rval)
	    } else if (ctod (str, ip, dval) > 0) {
		call printf (fmtstr)
		    call pargd (dval)
	    } else {
		call sprintf (fmtstr, SZ_LINE, "%ss ")
	    	    call pargstr (format)
		call printf (fmtstr)
		    call pargstr (str)
	    }
	} else
	    call error (0, "Internal error while processing format")
end


# PRINT_TITLES - Print all the keywords in the table, in the same order they
# have in the table, with the corresponding formats from the format table.
# A newline is printed at the end of the titles (keywords)

procedure print_titles ()

int	i, ip, junk
char	width[SZ_LINE], format[SZ_LINE], dict[SZ_LINE]

include	"dfits.com"
int	strext()

begin
	# Print all the keywords in the title line
	do i = 1, nkeywords {

	    # Build format
	    ip = 2
	    call sprintf (dict, SZ_LINE, "%s.")
		call pargstr (FORMAT_DICT)
	    junk = strext (Memc[fmt_table[i]], ip, dict, YES, width, SZ_LINE)
	    call sprintf (format, SZ_LINE, "%%%s.%s")
		call pargstr (width)
		call pargstr (width)

	    # Print title or debug code (true -> debug active)
	    if (false) {
		call printf ("keyword = <%s>  format = <%s>  title = <")
		    call pargstr (Memc[key_table[i]])
		    call pargstr (format)
		    call print_string (Memc[key_table[i]], format, "s")
		    call printf (">\n")
		    call flush (STDOUT)
	    } else
	        call print_string (Memc[key_table[i]], format, "s")
	}

	# Print a newline at the end of the title line
	call printf ("\n")
end
