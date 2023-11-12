include	"mctable.h"


# MCT_CLEAR - Clear all table values with given value. Do not reset any
# table counter.

procedure mct_clearc (table, value)

pointer	table			# table descriptor
char	value			# value

begin
	# Check pointer and magic number
	if (table == NULL)
	    call error (0, "mct_clear: Null table pointer")
	if (MCT_MAGIC (table) != MAGIC)
	    call error (0, "mct_clear: Bad magic number")

	# Check table type
	if (MCT_TYPE (table) != TY_CHAR)
	    call error (0, "mct_clear: Wrong table type")

	# Move value to data buffer
	call amovkc (value, Memc[MCT_DATA (table)],
		     MCT_MAXROW (table) * MCT_MAXCOL (table))
end
