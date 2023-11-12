# MPCNTR - Find the star centroid. This code was originally written by
# George Jacoby in Fortran and translated almost without changes to SPP.
#
# NOTE: The procedure "getcenter" was not tranlated since it was already
# defined in the package library by the task "ringpars".

procedure mpcntr (im, ncols, nrows, xstart, ystart,
		  boxsize, xcntr, ycntr)

pointer	im			# image descriptor
int	ncols, nrows		# number of columns and rows of image
real    xstart, ystart		# initial star position
int	boxsize			# size of search box
real    xcntr, ycntr		# star position found (output)

int	x1, x2, y1, y2, half_box
int	nx, ny, try
real    xinit, yinit
pointer	bufptr
real    x_vect[100], y_vect[100]

pointer	imgs2r()

begin
        half_box = (boxsize - 1) / 2
        xinit = xstart
        yinit = ystart

        try = 0
1       x1 = amax1 (xinit - half_box, 1.0) + 0.5
        x2 = amin1 (xinit + half_box, float(ncols)) + 0.5
        y1 = amax1 (yinit - half_box, 1.0) + 0.5 
        y2 = amin1 (yinit + half_box, real(nrows)) + 0.5

        nx = x2 - x1 + 1
        ny = y2 - y1 + 1
 
        bufptr = imgs2r (im, x1, x2, y1, y2)

        call aclrr (x_vect, nx)
        call aclrr (y_vect, ny)

	# Sum all rows
        call rowsum (Memr[bufptr], x_vect, nx, ny)

	# Sum all columns
        call colsum (Memr[bufptr], y_vect, nx, ny)

	# Find centers
        call getcenter (x_vect, nx, xcntr)
        call getcenter (y_vect, ny, ycntr)

	# Add in offsets
        xcntr = xcntr + x1
        ycntr = ycntr + y1

        try = try + 1
        if (try == 1) {
            if ((abs(xcntr-xinit) > 1.0) && (abs(ycntr-yinit) > 1.0)) { 
                xinit = xcntr
                yinit = ycntr
                goto 1
            }
        }
end


# ROWSUM -- Sum all rows in a raster

procedure rowsum (v, row, nx, ny)

real    v[nx,ny]	# raster
real    row[nx]		# sum of rows
int	nx, ny		# dimension of the raster

int	i, j

begin
	do i = 1, ny
	    do j = 1, nx
		row[j] = row[j] + v[j,i]
end


# COLSUM -- Sum all columns in a raster

procedure colsum (v, col, nx, ny)

real	v[nx,ny]	# raster
real    col[nx]		# sum of columns
int	nx, ny		# dimension of the raster

int	i, j

begin
	do i = 1, ny
	    do j = 1, nx
		col[j] = col[j] + v[i,j]
end
