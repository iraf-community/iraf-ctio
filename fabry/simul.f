      function simul (n,a,x,eps,indic,nrc)
      real y(10),a(nrc,nrc),x(n)
      dimension	irow(10),jcol(10),jord(10)

      max=n
      if (indic.ge.0) max=n+1
      deter = 1.0

      do 7 k=1,n
      km1 = k-1
      pivot = 0.0

      do 3 i=1,n
      do 3 j=1,n
      if (k.eq.1) go to	2

      do 1 iscan=1,km1
      do 1 jscan=1,km1
      if (i.eq.irow(iscan)) go to 3
      if (j.eq.jcol(jscan)) go to 3
    1 continue

    2 if (abs(a(i,j)).le.abs(pivot)) go	to 3
      pivot = a(i,j)
      irow(k) =	i
      jcol(k) =	j
    3 continue

      if (abs(pivot).gt.eps) go	to 4
      simul = 0.0
      return
    4 irowk = irow(k)
      jcolk = jcol(k)

      do 5 j=1,max
    5 a(irowk,j) = a(irowk,j)/pivot

      a(irowk,jcolk) = 1.0/pivot
      do 7 i=1,n
      aijck = a(i,jcolk)
      if (i.eq.irowk) go to 7
      a(i,jcolk) = -aijck/pivot

      do 6 j=1,max
      if (j.ne.jcolk) a(i,j)=a(i,j)-aijck*a(irowk,j)
    6 continue

    7 continue

      do 8 i=1,n
      irowi = irow(i)
      jcoli = jcol(i)
      jord(irowi) = jcoli
      if (indic.ge.0) x(jcoli) = a(irowi,max)
    8 continue

      intch = 0
      nm1 = n-1

      do 9 i=1,nm1
      ip1 = i+1

      do 9 j=ip1,n
      if (jord(j).ge.jord(i)) go to 9
      jtemp = jord(j)
      jord(j) =	jord(i)
      jord(i) =	jtemp
      intch = intch+1
    9 continue

      if (indic.le.0) go to 10
      simul = deter
      return

   10 do 12 j=1,n
      do 11 i=1,n
      irowi = irow(i)
      jcoli = jcol(i)
   11 y(jcoli) = a(irowi,j)

      do 12 i=1,n
   12 a(i,j) = y(i)

      do 14 i=1,n
      do 13 j=1,n
      irowj = irow(j)
      jcolj = jcol(j)
   13 y(irowj) = a(i,jcolj)

      do 14 j=1,n
   14 a(i,j) = y(j)

      simul = deter
      return
      end
