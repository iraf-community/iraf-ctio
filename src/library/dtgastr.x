include	<pkg/dttext.h>

# DTGASTR -- Get a string array
procedure dtgastr (dt, record, field, outstr, nstr, maxch)

pointer	dt			# database descriptor
int	record			# record number
char	field[ARB]		# field name
char	outstr[ARB]		# output string
int	nstr			# number of strings
int	maxch			# max number of characters in outstr

char	name[SZ_LINE], value[SZ_LINE]
int	i, op
int	fscan(), nscan(), strlen()
bool	streq()

begin
	# Check record range
	if ((record < 1) || (record > DT_NRECS(dt)))
	    call error (0, "Database record request out of bounds")

	call seek (DT(dt), DT_OFFSET(dt, record))

	# Search for record
	while (fscan (DT(dt)) != EOF) {
	    call gargwrd (name, SZ_LINE)

	    # Check if record found or start
	    # of next record
	    if (streq (name, "begin"))
		break
	    else if (streq (name, field)) {
		call gargi (nstr)
		if (nscan() != 2)
		    call error (0, "Error in database field value")

		# Read strings and concatenate them into
		# the output string, delimited by spaces
		outstr[1] = EOS
		do i = 1, nstr {

		    op = 1

		    if (fscan (DT(dt)) == EOF)
		        call error (0, "Error in database field value")

		    call gargwrd (value, SZ_LINE)

		    if (nscan() != 1)
		        call error (0, "Error in database field value")

		    call strcat (value, outstr, maxch)
		    call strcat (" ", outstr, maxch)
		    op = op + strlen (outstr)
		}

		# Take out the trailing blank
		outstr[op-1] = EOS

		return
	    }
	}

	# Record search failed
	call error (0, "Database field not found")
end
