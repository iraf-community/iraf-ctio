include	"mctable.h"


# MCT_SPUT - Put value sequentally (generic)

procedure mct_sputd (table, value)

pointer	table			# table descriptor
double	value			# data value

int	row, col		# nxt row, and column

errchk	mct_putd

begin
	# Check pointer and magic number
	if (table == NULL)
	    call error (0, "mct_sput: Null table pointer")
	if (MCT_MAGIC (table) != MAGIC)
	    call error (0, "mct_sput: Bad magic number")
	
	# Check table type
	if (MCT_TYPE (table) != TY_DOUBLE)
	    call error (0, "mct_sput: Wrong table type")

	# Get next position 
	row = max (MCT_NPROWS (table), 1)
	col = MCT_NPCOLS (table) + 1

	# Test if it's necessary to go to
	# the next row.
	if (col > MCT_MAXCOL (table)) {
	    col	= 1
	    row = row + 1
	}

	# Enter value
	call mct_putd (table, row, col, value)
end
