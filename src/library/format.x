.help fmt
Formatted I/O procedures.

This is a set of functions used to do formatted output to the standard output,
the standard error, or to a file. The difference between these
functions and the FMTIO procedures printf(), eprintf(), and fprintf() is
that the ones here are such that they request the values to be
printed only if they are needed, by means of an user supplied procedure.
In this way, the user does not have to supply all the values to print, but
instead they are supplied on the fly.

The functions supplied here support a subset of the format
codes supplied by FMTIO. The features that are not implemented are the
"rn" format code (convert to integer in any radix) and "-n" and "0n"
field width specifications, and some escape sequences (string and
character delimiter and octal value of character).

The routines expect a format string, a starting index in the format string
a user supplied procedure, and a pointer to a user supplied structure. The
functions parse the format string, and if they find a format specification
starting with a "%" they request the appropiate value by calling the user
supplied procedure. The user supplied structure is passed directly to the user
supplied procedure, and is intended for passing information from the
user's program to the user supplied procedure without having to use
common blocks.

The functions return the number of characters of the format string that
were processed in each call. The caller will know that the format string
is completely processed when a zero is returned.

The user supplied procedure has the following structure:

	userproc (dtype, bval, cval, lval, dval, xval, strval, maxch, ptr)

where "dtype" is the data type of the value to be returned, in one of the
"*val" parameters, and "ptr" is the pointer to the user supplied
procedure. The "dtype" parameter can take the following values: TY_BOOL,
TY_CHAR, TY_LONG, TY_DOUBLE, and TY_COMPLEX. Single characters are
distinguished from character strings because the "maxch" parameter is
zero for the formers.
.nf

Entry points:

	nchars = fmt_printf  (format, ip, userproc, userstruc)
	nchars = fmt_eprintf (format, ip, userproc, userstruc)
	nchars = fmt_fprintf (fd, format, ip, userproc, userstruc)
.fi
.endhelp

# Start of a format specification
define	START_FORMAT		'%'

# Start of a escape sequence.
define  START_ESCAPE		'\\'

# Check if the character is one of the possible characters used
# to specify an output format (bcdefghmsz).
define	IS_FORMAT		($1=='b'||$1=='c'||$1=='d'||$1=='e'||$1=='f'||$1=='g'||$1=='h'||$1=='m'||$1=='s'||$1=='z')


# FMT_PRINTF -- Print arbitrary values to the standard output using an
# arbitrary format string.

int procedure fmt_printf (format, ip, userproc, userstruc)

char	format[ARB]		# format string
int	ip			# index to starting character in format string
extern	userproc()		# user supplied function
pointer	userstruc		# pointer to user defined structure

int	fmt_fprintf()

begin
	return (fmt_fprintf (STDOUT, format, ip, userproc, userstruc))
end


# FMT_EPRINTF -- Print arbitrary values to the standard error using an
# arbitrary format string.

int procedure fmt_eprintf (format, ip, userproc, userstruc)

char	format[ARB]		# format string
int	ip			# index to starting character in format string
extern	userproc()		# user supplied function
pointer	userstruc		# pointer to user defined structure

int	fmt_fprintf()

begin
	return (fmt_fprintf (STDERR, format, ip, userproc, userstruc))
end


# FMT_FPRINTF -- Print arbitrary values to a file using an arbitrary format
# string. This procedure call be called with a single format string as many
# times as values need to be printed. It returns the number of characters in
# the format string that were processed, or zero if the format string is
# exhausted.

int procedure fmt_fprintf (fd, format, ip, userproc, userstruc)

int	fd			# output file descriptor
char	format[ARB]		# format string
int	ip			# index to starting character in format string
extern	userproc()		# user supplied function
pointer	userstruc		# pointer to user defined structure

bool	new
int	len, old_ip

int	strlen()
errchk	fmt_format(), fmt_escape()

begin
	# Initialize variables
	old_ip = ip
	new    = true
	len    = strlen (format)

	# Loop over the format string until either the end of the
	# string is found, or one value is printed.
	while (ip <= len) {
	    switch (format[ip]) {
	    case START_FORMAT:
		if (new) {
		    call fmt_format (fd, format, ip, userproc, userstruc)
		    new = false
		} else
		    break
	    case START_ESCAPE:
		call fmt_escape (fd, format, ip)
	    default:
		call fprintf (fd, "%1.1s")
		    call pargstr (format[ip])
		ip = ip + 1
	    }
	}

	# Return number of characters processed
	return (ip - old_ip)
end


# FMT_FORMAT -- Process format string starting with a "%".

procedure fmt_format (fd, format, ip, userproc, userstruc)

int	fd			# output file descriptor
char	format[ARB]		# format string
int	ip			# index to starting character in format string
extern	userproc()		# user supplied function
int	userstruc		# pointer to user defined structure

int	old_ip
bool	bval
char	cval
long	lval
double	dval
complex	xval
pointer	sp, fmt, strval, errstr

errchk	userproc()

begin
#call eprintf ("fmt_form: fd=%d, format=(%s), ip=%d\n")
#call pargi (fd)
#call pargstr (format)
#call pargi (ip)

	# Allocate string space
	call smark  (sp)
	call salloc (fmt,    SZ_LINE, TY_CHAR)
	call salloc (strval, SZ_LINE, TY_CHAR)
	call salloc (errstr, SZ_LINE, TY_CHAR)

	# Find the end of the format string
	old_ip = ip
	for (ip = old_ip + 1; format[ip] != EOS && !IS_FORMAT (format[ip]);
	     ip = ip + 1)
	    ;
	ip = ip + 1

	# Extract single format
	call strcpy (format[old_ip], Memc[fmt], ip - old_ip)

#call eprintf ("fmt_form: fmt=(%s), old_ip=%d, ip=%d\n")
#call pargstr (Memc[fmt])
#call pargi (old_ip)
#call pargi (ip)

	# Branch on data type
	switch (format[ip - 1]) {
	case 'b':
	    call userproc (TY_BOOL, bval, cval, lval, dval, xval,
			   Memc[strval], 0, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargb (bval)

	case 'c':
	    call userproc (TY_CHAR, bval, cval, lval, dval, xval,
			   Memc[strval], 0, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargc (cval)

	case 'd', 'u', 'o', 'x':
	    call userproc (TY_LONG, bval, cval, lval, dval, xval,
			   Memc[strval], 0, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargl (lval)

	case 'e', 'f', 'g', 'h', 'm':
	    call userproc (TY_DOUBLE, bval, cval, lval, dval, xval,
			   Memc[strval], 0, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargd (dval)

	case 's':
	    call userproc (TY_CHAR, bval, cval, lval, dval, xval,
			   Memc[strval], SZ_LINE, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargstr (Memc[strval])

	case 'z':
	    call userproc (TY_COMPLEX, bval, cval, lval, dval, xval,
			   Memc[strval], 0, userstruc)
	    call fprintf (fd, Memc[fmt])
		call pargx (xval)

	default:
	    call sfree (sp)
	    call sprintf (Memc[errstr], SZ_LINE, "Illegal format string [%s]")
		call pargstr (Memc[fmt])
	    call error (0, Memc[errstr])
	}

	# Free memory
	call sfree (sp)
end


# FMT_ESCAPE -- Process escape sequences starting with a "\".

procedure fmt_escape (fd, format, ip)

int	fd			# output file descriptor
char	format[ARB]		# format string
int	ip			# starting index in format string

pointer	sp, errstr

begin
#call eprintf ("fmt_escape: fd=%d, format=(%s), ip=%d\n")
#call pargi (fd)
#call pargstr (format)
#call pargi (ip)

	# Allocate string space
	call smark  (sp)
	call salloc (errstr, SZ_LINE, TY_CHAR)

	# Branch on escape character (?)
	switch (format[ip + 1]) {
	case 'b':
	    call fprintf (fd, "\b")		# backspace
	case 'f':
	    call fprintf (fd, "\f")		# form feed
	case 'n':
	    call fprintf (fd, "\n")		# newline
	case 'r':
	    call fprintf (fd, "\r")		# carriage return
	case 't':
	    call fprintf (fd, "\t")		# horizontal tab
	case '\\':
	    call fprintf (fd, "\\")		# backslash
	default:
	    call sfree (sp)
	    call sprintf (Memc[errstr], SZ_LINE,
		"Illegal escape sequence [%s]")
		call pargstr (format[ip - 1])
	    call error (0, Memc[errstr])
	}

	# Skip to the beginning of next token
	ip = ip + 2

	# Free memory
	call sfree (sp)
end
