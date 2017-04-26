include <pattern.h>
include	"dfits.h"


# RFT_DISP_HEADER -- Display a FITS header.
# EOT is detected by an EOF on the first read and EOF is returned to the calling
# routine.  Any error is passed to the calling routine.

int procedure rft_disp_header (fits_fd, fitsfile)

int	fits_fd			# FITS file descriptor
char	fitsfile[ARB]		# FITS file name

int	i, nread
char	card[LEN_CARD+1]

int	rft_init_read_pixels(), rft_read_pixels(), strmatch()

pointer	card_table[MAX_CARDS]	# pointers to cards in stack
int	ncards			# number of cards in table
pointer	sp
int	n, rec_count

errchk	rft_init_read_pixels, rft_read_pixels

include	"dfits.com"

begin
	# Initialize
	card[LEN_CARD + 1] = '\n'
	card[LEN_CARD + 2] = EOS
	ncards = 0

	# Check how to start
	if (long_header) {
	    call printf ("File: %s\n")
		call pargstr (fitsfile)
	} else
	    call smark (sp)

	# Header is character data in FITS_BYTE form
	i = rft_init_read_pixels (len_record, FITS_BYTE, LSBF, TY_CHAR)

	# Loop until the END card is encountered
	nread = 0
	rec_count = 0
	repeat {
	    i = rft_read_pixels (fits_fd, card, LEN_CARD, rec_count, 1) 

	    if ((i == EOF) && (nread == 0)) {		# At EOT
		return (EOF)
	    } else if ((nread == 0) && strmatch (card, "^SIMPLE  ") == 0) {
		call flush (STDOUT)
		call error (30, "RFT_DISP_HEADER: Not a FITS file")
	    } else if (i != LEN_CARD) {
		call error (2, "RFT_DISP_HEADER: Error reading FITS header")
	    } else
		nread = nread + 1

	    # Check if prints the card or stores it for future use
	    if (long_header) {
		call printf ("%s")
		    call pargstr (card)
	    } else if (ncards < MAX_CARDS && nkeywords > 0) {
		ncards = ncards + 1
		call salloc (card_table[ncards], LEN_CARD + 1, TY_CHAR)
		call strcpy (card, Memc[card_table[ncards]], LEN_CARD)
	    }

	} until (strmatch (card, "^END   ") != 0)

	# Print cards previously stored
	if (!long_header) {
	    do n = 1, nkeywords {
		if (strmatch (Memc[key_table[n]], "^FILENAME") != 0)
		    call print_string (fitsfile, Memc[fmt_table[n]],
				       opt_table[n])
		else
		    call print_card (card_table, ncards, n)
	    }
	    call printf ("\n")
	}

	# Check how to finish
	if (long_header)
    	    call printf ("\n")
	else
	    call sfree (sp)

	# Return code
	return (OK)
end


# PRINT_CARD - Searchs in the card table for a card that matchs a given
# keyword, extracts the data from that card and prints it according to a
# given format. Leading spaces, single quotes and comments are removed from
# the data.

procedure print_card (card_table, ncards, index)

pointer	card_table[MAX_CARDS]	# table of cards
int	ncards			# number of table entries
int	index			# index of the format table to use

char	newkey[SZ_KEYWORD + 1]	# new keyword
char	str[LEN_CARD]		# card data string
int	count			# local string char. count
int	pos			# position in the card table
bool	quote			# inside string flag
bool	leading			# leading spaces flag
int	i			# aux.
char	c

int	strmatch()
include	"dfits.com"

begin
	# Add metacharacter to new keyword to force comparision at the
	# begining of the card
	newkey[1] = CH_BOL
	newkey[2] = EOS
	call strcat(Memc[key_table[index]], newkey, SZ_KEYWORD + 1)

	# Search the keyword in the card table
	for (pos=1; pos<=ncards && strmatch(Memc[card_table[pos]],
	     newkey)==0; pos=pos+1)
		;	# empty for body

	# Check if the keyword was found in the cards, extract the data
	# from the card and print it
	if (pos < ncards) {

	    # copy data from the card to local string, skipping single
	    # quotes, leading spaces and taking into account strings.
	    # End with a comment start or the end of the card
	    count = 1
	    quote = false
	    leading = true
	    do i = COL_VALUE, LEN_CARD {
		c = Memc[card_table[pos] + i - 1]
		if (c == ' ' && leading)
		    next	
		else if (c == '\'') {
		    if (quote)
			break
		    else {
			quote = true
			next
		    }
		} else if (c == '/' && !quote)
		    break
		else {
		    str[count] = c
		    count = count + 1
		    leading = false
		}
	    }
	    str[count] = EOS	# mark EOS

	} else
	    str[1] = EOS	# keyword not present in card table
	
	# Print the string and a trailing space
	call print_string (str, Memc[fmt_table[index]], opt_table[index])
end
