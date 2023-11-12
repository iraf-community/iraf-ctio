include <error.h>
include	"dfits.h"

# RFT_DISP_FITZ -- Display a FITS file. An EOT is signalled by returning EOF.

int procedure rft_disp_fitz (fitsfile, filenumber)

char	fitsfile[ARB]		# FITS file name
int	filenumber		# FITS file number

char	name[SZ_FNAME]
int	fits_fd, stat
int	rft_disp_header(), mtopen(), strmatch()

errchk	rft_disp_header, mtopen, close

include	"dfits.com"

begin
	# Open input FITS data
	fits_fd = mtopen (fitsfile, READ_ONLY, 0)

	# Convert the filename if it's a tape read
	if (strmatch (fitsfile, "^mta") != 0) {
	    call sprintf (name, SZ_FNAME, "[%d]")
		call pargi (filenumber)
	} else
	    call strcpy (fitsfile, name, SZ_FNAME)

	# Read header.  EOT is signalled by an EOF status from 
	# fits_disp_header.

	# Checks possible error in reading header
	iferr {
	    stat = rft_disp_header (fits_fd, name)
	    if (stat == EOF)
	        call printf ("End of data\n")
	} then
	    call erract (EA_WARN)

	# Close file
	call close (fits_fd)

	# Return error code
	return (stat)
end
