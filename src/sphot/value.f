	function value (ix, iy, sdata, ndata, i1, i2, j1, j2)
c
c return the intensity value at physical (ix,iy) in the image
c
	dimension sdata(ndata)
	integer	ix, iy, i1, i2, j1, j2
c
	index = (ix - i1 + 1) + (iy - j1)*(i2 - i1 + 1)
	value = sdata (index)
c
	return
	end
 
