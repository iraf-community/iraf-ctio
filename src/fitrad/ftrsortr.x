# FTR_SORT -- Sort two arrays based on the values on the first one.

procedure ftr_sortr (a, b, npts)

real	a[npts], b[npts]	# arrays to sort
int	npts			# number of points

int	i
pointer	index, buffer
pointer	sp, ptr

int	ftr_cmpr()
extern	ftr_cmpr

begin
	# Allocate memory for indices and data
	call smark (sp)
	call salloc (index, npts, TY_POINTER)
	call salloc (buffer, npts, TY_REAL)

	# Copy first array into temporary buffer
	call amovr (a, Memr[buffer], npts)

	# Initialize pointers
	do i = 1, npts
	    Memi[index + i - 1] = buffer + i - 1

	# Sort pointers
	call qsort (Memi[index], npts, ftr_cmpr)

	# Rearrange first array
	do i = 1, npts {
	    ptr = Memi[index + i - 1]
	    a[i] = Memr[ptr]
	}

	# Rearrange second array
	call amovr (b, Memr[buffer], npts)
	do i = 1, npts {
	    ptr = Memi[index + i - 1]
	    b[i] = Memr[ptr]
	}

	# Free memory
	call sfree (sp)
end


# FTR_COMP -- Sort comparison function (ascending order).

int procedure ftr_cmpr (i, j)

pointer	i, j		# element pointers

begin
	# Compare elements
	if (Memr[i] < Memr[j])
	    return (-1)
	else if (Memr[i] > Memr[j])
	    return (1)
	else
	    return (0)
end
