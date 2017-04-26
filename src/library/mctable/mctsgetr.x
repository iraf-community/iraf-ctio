include	"mctable.h"


# MCT_SGET - Get value sequentally (generic)

int procedure mct_sgetr (table, value)

pointer	table			# table descriptor
real	value			# data value (output)

int	row, col		# next row, and column

real	mct_getr()

begin
	# Check pointer and magic number
	if (table == NULL)
	    call error (0, "mct_sget: Null table pointer")
	if (MCT_MAGIC (table) != MAGIC)
	    call error (0, "mct_sget: Bad magic number")
	
	# Check table type
	if (MCT_TYPE (table) != TY_REAL)
	    call error (0, "mct_sget: Wrong table type")

	# Get next position 
	row = max (MCT_NGROWS (table), 1)
	col = MCT_NGCOLS (table) + 1

	# Test if it's necessary to go to the next row.
	if (col > MCT_MAXCOL (table)) {
	    col	= 1
	    row = row + 1
	}

	# Get value and return status
	iferr (value = mct_getr (table, row, col))
	    return (EOF)
	else
	    return (OK)
end
