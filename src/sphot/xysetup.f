	subroutine xysetp (xi, yi, rstar, rdel, rsky2, nx, ny, 
     1  i1, i2, j1, j2, nmax, ndata, ier)
c
c  check entire star is within picture - return boundaries
c   of box to extract if ok, error code if a problem
c
c	these are the input arguments:
c		xi, yi		initial x,y star position
c		rstar		radius of the summing aperture
c		rdel		maximum shift in r (to allow for
c				change in centroid position)
c		rsky2		the outer radius of the sky annulus
c		nx, ny		# rows, # columns in image
c	and the ouput ones:
c		i1, i2, j1, j2	boundaries of box to be extracted
c				in original picture
c		ndata		total # of points in data array
c		ier		error code (if 0, all ok)
c				=1   star too close to edge
c				=2   data rectangle exceeds memory
c
c	note that it is ok for some of the sky aperture to fall
c	outside the image area, but not for any of the star aperture
c
	integer	ix, iy, nx, ny, ier, imin, imax, jmax, rmax
	integer i1, i2, j1, j2, ndata
	real	rstar, rdel
c
	ier = 0
c
	ix = int(xi)
	iy = int(yi)
	imin = int (rstar + rdel + 0.5)
	imax = nx - imin 
	jmax = ny - imin
c
	if (ix.lt.imin.or.iy.lt.imin) goto 900
	if (ix.gt.imax.or.iy.gt.jmax) goto 900
c
c now determine the box boundaries allowing for a centroid shift
	rmax = int (rsky2 + rdel + 0.5)
	i1 = ix - rmax 
	if (i1.lt.1) i1 = 1
	i2 = ix + rmax
	if (i2.gt.nx) i2 = nx
	j1 = iy - rmax
	if (j1.lt.1) j1 = 1
	j2 = iy + rmax
	if (j2.gt.ny) j2 = ny
	ndata = (i2 - i1 + 1)*(j2 - j1 + 1)

c Error condition no longer neccesary with the SPP interface
c	if (ndata.gt.nmax) ier = 2

	return
c
900	ier = 1
	return
	end
 
