include	<imhdr.h>

# IDS_HDRI -- Load an integer value from the header

procedure ids_hdri (im,	field, ival)

pointer	im
char	field[ARB]
int	ival

int	ival1, imgeti()

begin
	iferr (ival1 =	imgeti (im, field))
	    ival1 = ival
	ival =	ival1
end

# IDS_HDRR -- Load a real value	from the header

procedure ids_hdrr (im,	field, rval)

pointer	im
char	field[ARB]
real	rval

real	rval1, imgetr()

begin
	iferr (rval1 =	imgetr (im, field))
	    rval1 = rval
	rval =	rval1
end


# GET_HDRR -- Load a real value	from the header.

real procedure get_hdrr	(im, field)

pointer	im
char	field[ARB]

real	rval, imgetr()

begin
	iferr (rval = imgetr (im, field))
	    rval = INDEF
	return	(rval)
end

#  IDS_ADDI -- Add a integer parameter to the image header.

procedure ids_addi (im,	field, value)

pointer	im			# IMIO pointer
char	field[ARB]		# Header parameter
int	value			# Value

begin
	if (!IS_INDEFI	(value)) {
#	    iferr (call imdelf (im, field))
#		;
	    call imaddi (im, field, value)
	}
end

#  IDS_ADDR -- Add a real parameter to the image header.

procedure ids_addr (im,	field, value)

pointer	im			# IMIO pointer
char	field[ARB]		# Header parameter
real	value			# Value

begin
	if (!IS_INDEFR	(value)) {
	    iferr (call imdelf	(im, field))
		;
	    call imaddr (im, field, value)
	}
end

#  IDS_SEX -- Format and add a sexigesimal string parameter to the image header.

procedure ids_sex (im, field, value)

pointer	im			# IMIO pointer
char	field[ARB]		# Header parameter
real	value			# Value

char	str[20]

begin
	if (!IS_INDEFR	(value)) {
	    iferr (call imdelf	(im, field))
		;
	    call sprintf (str,	20, "%-18.1h")
		 call pargr (value)
	    call imastr (im, field, str)
	}
end

#  IDS_ADDS -- Add a string parameter

procedure ids_adds (im,	field, str)

pointer	im			# IMIO pointer
char	field[ARB]		# Header parameter
char	str[20]

begin
	call imastr (im, field, str)
end
