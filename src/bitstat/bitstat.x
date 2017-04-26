include <mach.h>

# BST_LINE[SIL] -- Process single image line and update the counters
# for ones and zeroes.



procedure bst_lines (line, npix, maxbits, zero, one)

short	line[npix]		# image line
int	npix			# line length
int	maxbits			# max number of bits in data type
long	zero[NBITS_INT]		# "0" counter (modified)
long	one[NBITS_INT]		# "1" counter (modified)

int	i, bit
short	sval

begin
	# Loop over the image line
	do i = 1, npix {

	    # Get the next pixel value
	    sval = line[i]

	    # Loop over all the bits in each pixel until all the pixels
	    # are traversed. The pixel value is divided by two each time
	    # in order to have the bit in the LSB position.
	    for (bit = 1; bit <= maxbits; bit = bit + 1) {
		if (mod (int(sval), 2) == 0)
		    zero[bit] = zero[bit] + 1
		else
		    one[bit] = one[bit] + 1
		sval = sval / 2
	    }
	}
end



procedure bst_linei (line, npix, maxbits, zero, one)

int	line[npix]		# image line
int	npix			# line length
int	maxbits			# max number of bits in data type
long	zero[NBITS_INT]		# "0" counter (modified)
long	one[NBITS_INT]		# "1" counter (modified)

int	i, bit
int	ival

begin
	# Loop over the image line
	do i = 1, npix {

	    # Get the next pixel value
	    ival = line[i]

	    # Loop over all the bits in each pixel until all the pixels
	    # are traversed. The pixel value is divided by two each time
	    # in order to have the bit in the LSB position.
	    for (bit = 1; bit <= maxbits; bit = bit + 1) {
		if (mod (ival, 2) == 0)
		    zero[bit] = zero[bit] + 1
		else
		    one[bit] = one[bit] + 1
		ival = ival / 2
	    }
	}
end



procedure bst_linel (line, npix, maxbits, zero, one)

long	line[npix]		# image line
int	npix			# line length
int	maxbits			# max number of bits in data type
long	zero[NBITS_INT]		# "0" counter (modified)
long	one[NBITS_INT]		# "1" counter (modified)

int	i, bit
long	lval

begin
	# Loop over the image line
	do i = 1, npix {

	    # Get the next pixel value
	    lval = line[i]

	    # Loop over all the bits in each pixel until all the pixels
	    # are traversed. The pixel value is divided by two each time
	    # in order to have the bit in the LSB position.
	    for (bit = 1; bit <= maxbits; bit = bit + 1) {
		if (mod (lval, 2) == 0)
		    zero[bit] = zero[bit] + 1
		else
		    one[bit] = one[bit] + 1
		lval = lval / 2
	    }
	}
end


