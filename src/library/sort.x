.help sort Aug89
Sort Procedures.

These procedures sort a table of pointers to structures by mantaining a
table with the pointers, and a second table with the indices to these pointers,
which is what gets sorted. The index table is handled automatically by the
procedures. The sorting algorithm used is quick-sort.
.sp
The length of the pointer table is defined at creation time and it cannot
be increased later (although this would be a natural extension to do).
The sort tables and all its associated structures can be freed by calling
srt_free().
.sp
Every time srt_put() is called a structure of the specified length is
allocated, and the pointer to it is returned to the caller. It is up to
the caller to fill the structure with the appropiate values.
.sp
Pointers can be retrieved sequentially calling srt_get(). This will return
the next pointer in the sorted order. If no sort was done they will be
returned by the order of entering into the table.
.sp
The sorted direction (not the order) can be set by calling srt_head(),
or srt_tail(). The first one will start getting from the beginning of the to
the end, and the latter from the end of to the beginning, of the sorted order
defined. These procedures should be called before calling srt_get().
.sp
Pointers are sorted by calling srt_sort(). The user must supply the comparison
function, which should be of the form:
.nf

	int compare (index1, index2)
where
	int index1, index2

.fi
The pointer to the structures can be obtained by calling srt_ptr() with the
indices values. The user function should return -1 if the object indexed by
index1 is less than the object indexed by index2, 0 if they are equal, and
1 otherwise.
.nf

Entry points:

	pointer = srt_init (length)		Initialize sort descriptor
		  srt_free (sd)			Free sort descriptor

	pointer = srt_get (sd)			Get next pointer
	pointer = srt_put (sd, length)		Put next pointer

		  srt_head (sd)			Start getting from the beginning
		  srt_tail (sd)			Start getting from the end

	int	= srt_nget (sd)			Get srt_get() counter
	int	= srt_nput (sd)			Get srt_put() counter

	pointer = srt_ptr (sd, index)		Get pointer by index

		  srt_sort (sd, func)		Sort pointers
.fi
.endhelp

# Pointer Mem
define	MEMP	Memi

# Sort structure definition
define	LEN_STRUCT		6		# structure length
define	SORT_PINDICES		MEMP[$1+0]	# pointer to indices
define	SORT_PPOINTERS		MEMP[$1+1]	# pointer to pointers
define	SORT_LENGTH		Memi[$1+2]	# length of offsets/pointers
define	SORT_NPUT		Memi[$1+3]	# srt_put() counter
define	SORT_NGET		Memi[$1+4]	# srt_get() counter
define	SORT_INCGET		Memi[$1+5]	# srt_get() counter increment

# Individual access
define	SORT_INDEX		Memi[SORT_PINDICES ($1) + $2 - 1]    # offset
define	SORT_POINTER		Memi[SORT_PPOINTERS ($1) + $2 - 1]   # pointer


# SRT_INIT -- Allocate space for sort descriptyor and clear counters.

pointer procedure srt_init (length)

int	length			# sort table length

int	i
pointer	ptr

errchk	malloc()

begin
	# Allocate space for sort structure
	call malloc (ptr, LEN_STRUCT, TY_STRUCT)
	call malloc (SORT_PINDICES (ptr), length, TY_INT)
	call malloc (SORT_PPOINTERS (ptr), length, TY_POINTER)

	# Clear offsets and pointers
	do i = 1, length {
	    SORT_INDEX (ptr, i) = i
	    SORT_POINTER (ptr, i) = NULL
	}

	# Store length
	SORT_LENGTH (ptr) = length

	# Clear counters. The inrement is set to 1,
	# i.e., the same as a call to srt_head().
	SORT_NPUT (ptr) = 0
	SORT_NGET (ptr) = 0
	SORT_INCGET (ptr) = 1

	# Return pointer to structure
	return (ptr)
end


# SRT_FREE -- Free sort descriptor.

procedure srt_free (sd)

pointer	sd			# sort descriptor

int	i

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_free: Null pointer")

	# Free user structures
	do i = 1, SORT_NPUT (sd)
	    call mfree (SORT_POINTER (sd, i), TY_STRUCT)

	# Free tables
	call mfree (SORT_PINDICES (sd), TY_INT)
	call mfree (SORT_PPOINTERS (sd), TY_POINTER)
	call mfree (sd, TY_STRUCT)
end


# SRT_GET -- Get next pointer.

pointer procedure srt_get (sd)

pointer	sd			# sort descriptor

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_get: Null pointer")

	# Count
	SORT_NGET (sd) = SORT_NGET (sd) + SORT_INCGET (sd)

	# Return pointer to structure
	return (SORT_POINTER (sd, SORT_INDEX (sd, SORT_NGET (sd))))
end


# SRT_PUT -- Get pointer for new entry.

pointer procedure srt_put (sd, length)

pointer	sd			# sort descriptor
int	length			# entry length

pointer	ptr

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_put: Null pointer")

	# Count entry
	SORT_NPUT (sd) = SORT_NPUT (sd) + 1

	# Allocate structure and put pointer
	# into the table
	call malloc (ptr, length, TY_STRUCT)
	SORT_POINTER (sd, SORT_NPUT (sd)) = ptr

	# Return pointer
	return (ptr)
end


# SRT_HEAD -- Start getting from the beginning.

procedure srt_head (sd)

pointer	sd		# sort descriptor

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_head: Null pointer")

	# Set counter and increment
	SORT_NGET (sd) = 0
	SORT_INCGET (sd) = 1
end


# SRT_TAIL -- Start getting from the end.

procedure srt_tail (sd)

pointer	sd		# sort descriptor

int	srt_nput()

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_tail: Null pointer")

	# Set counter and increment
	SORT_NGET (sd) = srt_nput (sd) + 1
	SORT_INCGET (sd) =  -1
end


# SRT_NGET -- Get current get counter.

int procedure srt_nget (sd)

pointer	sd			# sort descriptor

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_nget: Null pointer")

	# Return get counter
	return (SORT_NGET (sd))
end


# SRT_NPUT -- Get current put counter.

int procedure srt_nput (sd)

pointer	sd			# sort descriptor

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_nput: Null pointer")

	# Return put counter
	return (SORT_NPUT (sd))
end


# SRT_PTR -- Get pointer by index.

pointer procedure srt_ptr (sd, index)

pointer	sd			# sort descriptor
int	index			# pointer index

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_ptr: Null pointer")

	# Return pointer to structure
	return (SORT_POINTER (sd, index))
end


# SRT_SORT -- Sort offsets using a quick-sort algorithm. The user must
# supply the comparison function.

procedure srt_sort (sd, func)

pointer	sd			# sort descriptor
extern	func			# user comparison function

begin
	# Test descriptor
	if (sd == NULL)
	    call error (0, "srt_sort: Null pointer")

	# Call the quick-sort routine only if there are at least
	# two data points. Otherwise do nothing.
	if (SORT_NPUT (sd) > 1)
	    call qsort (Memi[SORT_PINDICES (sd)], SORT_NPUT (sd), func)
end
