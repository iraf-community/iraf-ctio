# FTR_SORT -- Sort two arrays based on the values on the first one.

procedure ftr_sortd (a, b, npts)

double	a[npts], b[npts]	# arrays to sort
int	npts			# number of points

int	i
pointer	index, buffer
pointer	sp, ptr

int	ftr_cmpd()
extern	ftr_cmpd

begin
	# Allocate memory for indices and data
	call smark (sp)
	call salloc (index, npts, TY_POINTER)
	call salloc (buffer, npts, TY_DOUBLE)

	# Copy first array into temporary buffer
	call amovd (a, Memd[buffer], npts)

	# Initialize pointers
	do i = 1, npts
	    Memi[index + i - 1] = buffer + i - 1

	# Sort pointers
	call qsort (Memi[index], npts, ftr_cmpd)

	# Rearrange first array
	do i = 1, npts {
	    ptr = Memi[index + i - 1]
	    a[i] = Memd[ptr]
	}

	# Rearrange second array
	call amovd (b, Memd[buffer], npts)
	do i = 1, npts {
	    ptr = Memi[index + i - 1]
	    b[i] = Memd[ptr]
	}

	# Free memory
	call sfree (sp)
end


# FTR_COMP -- Sort comparison function (ascending order).

int procedure ftr_cmpd (i, j)

pointer	i, j		# element pointers

begin
	# Compare elements
	if (Memd[i] < Memd[j])
	    return (-1)
	else if (Memd[i] > Memd[j])
	    return (1)
	else
	    return (0)
end
