	subroutine photom (xi,yi,sdata,ndata,i1,i2,j1,j2,
     1	rstr,r1,r2,
     2  cside,niter,rmax,isky,ksig,zpoint,time,gain,
     3  x,y,sky,nsky,sigsky,strsum,mag,nstar,err,sigmag,ier)
 
c  Mountain Photometry Code - Harvey Butcher's code in Fortran
c   		v1.0 	29mar87	pos
 
	dimension sdata(ndata)
	dimension xdata(21), ydata(21), skarray(2500)
	integer	cside, aravr
	real mag, err(3), sky(4), ksig
 
 
c CENTROID - determine the star centroid from first moments
 
	if (cside.gt.10) then
		ier = 1
		return
	endif
	mside = 2*cside + 1
 
c the basic centroid loop will be executed up to niter times
	ix0 = xi
	iy0 = yi
	ncent = 0
10	continue
 
c the (x,y) marginal distributions will be in xdata, ydata	
	call aclrr (xdata, mside)
	call aclrr (ydata, mside)
 
c first sum-up in the y direction (x center)
	do 100 i = ix0 - cside, ix0 + cside
		ix1 = i - (ix0 - cside) + 1
		do 100 j = iy0 - cside, iy0 + cside
			val = value (i,j,sdata,ndata,i1,i2,j1,j2)
			xdata(ix1) = xdata(ix1) + val
100	continue
 
c now in the x direction (y center)
	do 120 j = iy0 - cside, iy0 + cside
		jy1 = j - (iy0 - cside) + 1
		do 120 i = ix0 - cside, ix0 + cside
			val = value (i,j,sdata,ndata,i1,i2,j1,j2)
			ydata(jy1) = ydata(jy1) + val
120	continue
 
c estimate the centroid ignoring points below the mean
	call aavgr (xdata, mside, xmean, xsig)
	call aavgr (ydata, mside, ymean, ysig)
	x = 0.
	y = 0.
	xsum = 0.
	ysum = 0.
	do 135 k = 1, mside
		if (xdata(k).lt.xmean) goto 130
		xsum = xsum + xdata(k) - xmean
		x = x + float(ix0+k-cside-1)*(xdata(k)-xmean)
130		if (ydata(k).lt.ymean) goto 135
		ysum = ysum + ydata(k) - ymean
		y = y + float(iy0+k-cside-1)*(ydata(k)-ymean)
135	continue
	x = x/xsum
	y = y/ysum
		
c if new center > rmax from start, quit with an error message
	rdel = sqrt((x-xi)**2+(y-yi)**2)
	if (rdel.gt.rmax) then
		ier = 2
		return
	endif
c check to see if need/allowed to iterate centroid again
	ncent = ncent + 1
	if (ncent.gt.niter) then
		ier = 3
		return
	endif
c the final center must be in the central pixel of the box
	xdel = x - real (ix0)
	ix0 = int(x)
	ydel = y - real (iy0)
	iy0 = int(y)
	if (xdel.lt.0..or.xdel.gt.1.) goto 10
	if (ydel.lt.0..or.ydel.gt.1.) goto 10
 
 
c SKY - determine mean, median, and mode of sky
c	skarray has array of sky values
c	work with square of radius to save many sqrt calls
	nsky = 0
	r12 = r1**2
	r22 = r2**2
	do 200 i = i1, i2
		do 200 j = j1, j2
			xs = float (i)
			ys = float (j)
			rsk2 = radiu2 (xs, ys, x, y)
			if (rsk2.gt.r22.or.rsk2.lt.r12) goto 200
			nsky = nsky + 1
			skarray(nsky) = value(i,j,sdata,ndata,i1,i2,
     1			j1,j2)
200 	continue
 
c must have a 'reasonable' # of points in sky
	if (nsky.lt.10) then
		ier = 4
		return
	endif
 
c different sky determinations:
c		sky1	mean
c		sky2	median
c		sky3	mode (3*median - 2*mean)
c		sky4	mean with ksig sigma clipping
	call aavgr (skarray, nsky, sky(1), sigsky)
	sky(2) = amedr (skarray, nsky)
	sky(3) = 3.*sky(2) - 2.*sky(1)
	if (isky.eq.4) then	
		nsky = aravr (skarray, nsky, sky(4), sigsky, ksig)
	endif
	if (isky.ge.1.and.isky.le.4) then
		skyv = sky(isky)
	else
		ier = 5
		return
	endif
 
c SUMUP  sum all the star pixels within rs and subtract sky
c	 (no account of partial pixels .... yet)
	rstr2 = rstr**2
	strside = int (rstr + 1.)
	nstar = 0
	strsum = 0.
	ix1 = int(x+.5)
	iy1 = int(y+.5)
	do 300 i = ix1 - strside, ix1 + strside
		do 300 j = iy1 - strside, iy1 + strside
			rs2 = radiu2 (float(i),float(j),x,y)
			if (rs2.gt.rstr2) goto 300
			nstar = nstar + 1
			vals = value(i,j,sdata,ndata,i1,i2,
     1				j1,j2) - skyv
			strsum = strsum + vals
300	continue
	if (strsum.le.0.) then
		ier = 6
		return
	endif
 
	mag = zpoint - 2.5*log10(strsum/time)
 
c an attempt to estimate the random error in the magnitude: 3 sources
c	1	root(n) from the star (counts*gain)
c	2	error in the sky level
c		(estimated by error in the mean)
c	3	noise added by the sky itself within the aperture
c		(estimated from sky annulus)
c  the systematic errors (unknown) are likely to dominate
	ecnv = 2.5*log10(2.71828183)/strsum
	
	err(1) = strsum/gain
	err(3) = nstar * (sigsky**2)
	err(2) = err(3)/nsky
	sigsum = sqrt (err(1) + err(2) + err(3))
	
	sigmag = 2.5*log10(2.71828183)*sigsum/strsum
	err(1) = ecnv*sqrt(err(1))
	err(2) = ecnv*sqrt(err(2))
	err(3) = ecnv*sqrt(err(3))
 
	return
	end
 
