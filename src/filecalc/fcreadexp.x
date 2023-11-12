# FC_READEXP -- Read the expression string into a buffer. The expression
# string can be either a list of expressions or a file name. If it's a file
# name, the the file is opened and all the lines in the file are concatenated
# into the output buffer. Otherwise the expression string is copied into the
# output buffer without change. The output buffer is allocated inside the
# procedure and MUST be freed by the caller.

procedure fc_readexp (expressions, expbuf)

char	expressions[ARB]	# expression list
pointer	expbuf			# expression buffer (output)

int	fd
int	size
pointer	sp, line

int	open()
int	strlen()
int	fc_getline()

begin
#call eprintf ("fc_readexp: expressions=(%s)\n")
#call pargstr (expressions)

	# Allocate auxiliary string space
	call smark  (sp)
	call salloc (line, SZ_LINE, TY_CHAR)

	# Try to open the expression as a file. If it does exist
	# then concatenate input lines to the expression buffer.
	# Otherwise just copy the expression string into the
	# expression buffer.
	ifnoerr (fd = open (expressions, READ_ONLY, TEXT_FILE)) {

	    # Allocate expression buffer and initialize it with a null string
	    size = SZ_LINE
	    call malloc (expbuf, size, TY_CHAR)
	    call strcpy ("", Memc[expbuf], size)

	    # Read in lines from the file
	    while (fc_getline (fd, Memc[line], SZ_LINE) != EOF) {

		# Reallocate the expression buffer if there is not
		# enough space to append the line from the file
		if (strlen (Memc[line]) + strlen (Memc[expbuf]) >= size) {
		    size = 2 * size
		    call realloc (expbuf, size, TY_CHAR)
		}

		# Append line from file to expression buffer
		call strcat (Memc[line], Memc[expbuf], size)
	    }

	    # Close file
	    call close (fd)

	} else {
	    size = strlen (expressions)
	    call malloc (expbuf, size, TY_CHAR)
	    call strcpy (expressions, Memc[expbuf], size)
	}

	# Free memory
	call sfree (sp)
end
