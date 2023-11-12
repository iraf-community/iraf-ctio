      subroutine lfit (wave,flux,iord,old,error,rest,badpix,nbands)

      parameter	(CSPEED=2.998E5)
      parameter	(TOL   =1.0e-10)
c
c	Fits a line profile and extracts iord	parameters
c	the fitted parameters	and their errors are returned in the
c	arrays old and error.	 If no fit can be found, old(4)	is
c	set to BADPIX, old(1)	is set to the smallest positive	flux,
c	old(2) is set	to the largest flux.
c	The order of the parameters is: (1) continuum	flux,
c	(2) line strength, (3) velocity, (4) velocity	dispersion.
c
c modified to pass badpix value	and nr of bands	in arg list

      real wave(1),flux(1),q(4),sum(5,5),old(4),new(4),save(4),
     * error(4),rest, badpix
      integer iord, nbands
      logical con
      data itmax,conv /10,0.01/
c
c	make initial guesses
c
      if (iord.eq.3)then
      fmin = 10000.0
      fmax = 0.0

      do 5 i=1,nbands
	  if (flux(i).eq.badpix) go to 5
	  if ((flux(i).lt.fmin).and.(flux(i).gt.0.0)) fmin = flux(i)
	  if (flux(i).gt.fmax) then
	      fmax = flux(i)
	      vstart=CSPEED*(wave(i)-rest)/rest
	  end if
    5 continue

	old(1) = fmin
	old(2) = (fmax-fmin)
	old(3) = vstart
	old(4) = 2.5
      else
	old(4)=2.5
      end if
c
c	fit profile
c
      do 50 iter=1,itmax
	  do 10	i=1,5
	      do 10 j=1,5
   10 sum(i,j) = 0.0

	  ha1 =	rest * (1.0 + old(3) / CSPEED)
	  q3fact = -2.0	* rest / CSPEED

	  do 30	k=1,nbands
	      if (flux(k).eq.badpix) go	to 30
	      w1 = wave(k) - ha1

	      if (abs(w1).le.0.0001) w1	= 0.0001
	      ex1 = -0.5 * w1 *	w1 / (old(4)*old(4))
	      f1 = exp(ex1)
	      fit1 = old(2)*f1
	      err = flux(k) - old(1) - fit1

	      q(1) = 1.0
	      q(2) = f1
	      q(3) = q3fact * fit1 * ex1 / w1
	      q(4) = -2.0 * fit1 * ex1/old(4)
c
c	compute normal equations for corrections
c
	      do 20 i=1,iord
		  sum(i,iord+1)	= sum(i,iord+1)	+ err *	q(i)
		  do 20	j=1,iord
   20		      sum(i,j) = sum(i,j) + q(i) * q(j)

   30	  continue
c
c	solve	normal equations
c
	  det =	simul(iord,sum,new,TOL,1,5)
	  if (det.eq.0.0) go to	200
c
c	update coefficients and iterate
c
	  con =	.true.

	  do 40	i=1,iord
	      if(abs(old(i)).le.0.0001)	old(i) = 0.0001
	      if (abs(new(i)/old(i)).gt.conv) con = .false.
   40	      old(i) = old(i) +	new(i)

	  if (con) go to 60
   50 continue
c
c	fit once more, with errors
c
   60 do 70 i=1,5
	  do 70	j=1,5
   70	      sum(i,j) = 0.0

      sumysq = 0.0
      numb = 0
      ha1 = rest * (1.0	+ old(3) / CSPEED)
      q3fact = -2.0 * rest / CSPEED

      do 90 k=1,nbands
	  if (flux(k).eq.badpix) go to 90
	  numb = numb +	1
	  w1 = wave(k) - ha1
	  if (w1.eq.0.0) w1 = 0.0001
	  ex1 =	-0.5 * w1 * w1 / (old(4)*old(4))
	  f1 = exp(ex1)
	  fit1 = old(2)*f1
	  err =	flux(k)	- old(1) - fit1

	  q(1) = 1.0
	  q(2) = f1
	  q(3) = q3fact	* fit1 * ex1 / w1
	  q(4) = -2.0 *	fit1 * ex1/old(4)
c
c	compute normal equations for corrections
c
	  sumysq = sumysq + err	* err
	  do 80	i=1,iord
	      sum(i,iord+1) = sum(i,iord+1) + err * q(i)
	      do 80 j=1,iord
   80		  sum(i,j) = sum(i,j) +	q(i) * q(j)

   90 continue
c
c	solve	normal equations
c
      do 100 i=1,iord
  100	  save(i) = sum(i,iord+1)

      det = simul(iord,sum,new,TOL,0,5)
      if (det.eq.0.0) go to 200
c
c	update coefficients
c
      do 110 i=1,iord
  110	  old(i) = old(i) + new(i)
c
c	compute the errors
c
      do 120 i=1,iord
  120	  sumysq = sumysq - new(i) * save(i)

      if(sumysq.lt.0.) sumysq=-sumysq
      sigma = sqrt(sumysq/(numb-iord))

      do 130 i=1,iord
	  if (sum(i,i).lt.0.0) sum(i,i)	= 0.0
  130	  error(i) = sigma * sqrt(sum(i,i))

      old(4) = old(4) *	CSPEED / rest

      if(iord.lt.4)return

      error(4) = error(4) * CSPEED / rest
      return
c
c	matrix solution error
c
200   old(1) = badpix
      old(2) = badpix
      old(3) = badpix
      old(4) = badpix
      return
      end
