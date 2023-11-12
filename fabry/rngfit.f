c	RINGFIT.FOR - a	program	used to	solve for the
c	rings of the fabry-perot interferometer.  this is done by
c	solving	the equation:
c
c	wl= (a + b*z ) * cos( arctan( r/c ) )
c
c	where	a, b, and c are	the coefficients to be solved for and
c	r is the radius of a calibration ring, wl is the wavelength
c	of that ring,	z is the instrumental offset of	the capacitor
c	in the f-p etalon which allows tuning	the passband of	the
c	etalon.  the coeffecients are	found by a least-squares fit
c	which	inverts	the above equation and solves for a, b,	and c.
c	   this is equivalent	to the dispersion solution for a long-slit
c	spectrograph.
c
c	re-written:  5 june 1986    t.williams
c
c	modified for incorporation into iraf
c		    15 july 1987    g. jacoby
c
	subroutine rngfit (alam, z, r,	num, old, error, sigma)

	real*4	sum(4,4),old(3),q(3),new(3),save(3),error(3)
	real*4	alam(1),r(1),z(1)
	integer num
	logical con
	data conv,itmax /1.0e-06,25/
c
c do the least-squares fit - a first guess must	be stored in old
c
	do 6000 iter=1,itmax

	   do 2000 i=1,4

	      do 1000 j=1,4
		  sum(i,j) = 0.0
1000		   continue
2000		continue

	   sumysq = 0.0

	   do 4000 i=1,num
	      ang = atan2 (r(i),old(3))
	      fac = old(1) + old(2) * z(i)
	      err = alam(i) - fac * cos(ang)
	      q(1) = cos(ang)
	      q(2) = z(i) * q(1)
	      q(3) = r(i) * fac * sin(ang) / (old(3)*old(3) + r(i)*r(i))
	      sumysq =	sumysq + err * err

	      do 3500 j=1,3
		 sum (j,4) = sum(j,4)	+ err *	q(j)

		  do 3000 k=1,3
		    sum(j,k) = sum(j,k) + q(j) * q(k)
3000		 continue

3500		   continue
4000	  continue

	   do 4500 i=1,3
	      save(i) = sum(i,4)
4500		continue

	   det	= simul(3,sum,new,1.0e-10,0,4)
	   con	= .true.

	   do 5000 i=1,3
	      if (abs(new(i)/old(i)).gt.conv) con = .false.
	      old(i) =	old(i) + new(i)
5000		continue

	   if (con) go	to 40

6000	continue

   40	do 6500 i=1,3
	   sumysq = sumysq - new(i) * save(i)
6500	continue

	denom =	(num-3)
	if(denom.le.0) denom=1.0
	sigma = sqrt(sumysq/(denom))

	do 7000 i=1,3
	   error(i) = sigma * sqrt(sum(i,i))
7000	continue
c
	return
	end
c-----------------------------------------------------------------
	subroutine rngft0 (alam, z, r,	old)
c
c make an initial guess	at the coefficients of the ring
c
	real	alam(*), r(*), z(*), old(*)

	old(3)	= 2833.0
   	cos1   = cos(atan2(r(1),old(3)))
   	cos2   = cos(atan2(r(2),old(3)))
	old(2)	= (alam(1)/cos1	- alam(2)/cos2)	/ (z(1)	- z(2))
	old(1)	= alam(1) / cos1 - old(2) * z(1)

	return
	end
