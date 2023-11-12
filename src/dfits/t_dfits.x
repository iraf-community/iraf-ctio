include	<fset.h>
include <error.h>
include "dfits.h"

define	MAX_RANGES	100
define	NTYPES	7

# DFITS -- Display FITS format data.

procedure t_dfits()

char	infile[SZ_FNAME]	# fits file
char	in_fname[SZ_FNAME]	# input file name
char	file_list[SZ_LINE]	# list of tape files
char	form_name[SZ_FNAME]	# format file name

pointer	list
int	lenlist, junk
int	range[MAX_RANGES*2+1], nfiles, file_number, stat, fits_record

bool	clgetb()
int	strlen()
int	rft_disp_fitz(), decode_ranges(), get_next_number(), fntgfnb()
int	fntlenb()
int	mtfile()
pointer	fntopnb()
data	fits_record/2880/

pointer	sp

include	"dfits.com"

begin
	# Get DFITS parameters.
	call clgstr ("fits_file", infile, SZ_FNAME)
	long_header = clgetb ("long_header")
	len_record = fits_record

	# Set up the standard output to flush on newline.
	# This will slow up the task, specially if the output
	# is being redirected to a file, but it is necessary
	# to have updated information in case of an error.
	call fseti (STDOUT, F_FLUSHNL, YES)

	# Compute the number of files to be converted
	if (mtfile (infile) == YES)  {
	    list = NULL
	    if (infile[strlen(infile)] != ']')
	        call clgstr ("file_list", file_list, SZ_LINE)
	    else
	        call strcpy ("1", file_list, SZ_LINE)
	} else {
	    list = fntopnb (infile, YES)
	    lenlist = fntlenb (list)
	    call sprintf  (file_list, SZ_LINE, "1-%d")
		call pargi (lenlist)
	}

	# Decode the ranges
	if (decode_ranges (file_list, range, MAX_RANGES, nfiles) == ERR)
	    call error (1, "T_DFITS: Illegal file number list")

	# Check if it is necessary to allocate space on the stack and
	# read format file.
	if (!long_header) {
		call smark (sp)
		call clgstr ("form_file", form_name, SZ_FNAME)
		call read_formats (form_name)
		if (nkeywords > 0)
			call print_titles
	}

	# Read successive FITS files
	file_number = 0
	while (get_next_number (range, file_number) != EOF) {

	    # Get input file name
	    if (list != NULL) {
		in_fname[1] = EOS
		junk = fntgfnb (list, in_fname, SZ_FNAME)
	    } else {
	        call strcpy (infile, in_fname, SZ_FNAME)
	        if (infile[strlen(infile)] != ']') {
		    call sprintf (in_fname[strlen(in_fname)+1], SZ_FNAME,
		        "[%d]")
		        call pargi (file_number)
		}
	    }

	    # Display the header of a FITS file
	    # If EOT is reached then exit.
	    # If an error is detected then print a warning and continue with
	    # the next file.
	    iferr (stat = rft_disp_fitz (in_fname, file_number))
		call erract (EA_FATAL)
	    if (stat == EOF)
		break
	}


	# Close fits file (on disk)
	if (list != NULL)
	    call fntclsb (list)

	# Release formats in stack if previouslly allocated
	if (!long_header)
		call sfree (sp)
end
