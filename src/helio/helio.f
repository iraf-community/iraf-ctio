C	Compute the heliocentric julian date and other useful times
c...modified by nbs 20 oct 1986
c...modified by wgw 30 dec 1987
c...modifieg by pg  21 jan 1988

	SUBROUTINE HELJD(RA,DEC,MONTH,DAY,YEAR,UT,LATITUDE,LONGITUDE,
     #			 JD,HJD,LST,HA,Z,AIRMAS,V)

C	Compute heliocentric julian date
C	Input quantities:
C	RA=Right ascension (radians)		[double]
C	DEC=Declination (radians) 		[double]
C	MONTH= month (1 to 12)			[integer]
C	DAY=UT date of the month		[double]
C	YEAR=Year (19??)			[double]
C	UT=UT time (hours)			[double]
C	LATITUDE=Oservatory lat. (degress)	[double]
C	LONGITUDE=Observatory long. (hours)	[double]
C
C	Output quantities:
C	JD=Julian date			
C	HJD=Returned heliocentric julian date	[double]
C	LST=Local siderial time (radians)	[double]
C	HA=Hour angle (radians)			[double]
C	Z=Zenith distance (radians)		[double]
C	AIRMAS=Air mass				[double]
C	V=Heliocentric rv correction		[double]
C
C
C	Written by:	Richard Stover
C			Lick Observatory
C			University of California
C			Santa Cruz, CA 95064

	IMPLICIT DOUBLE PRECISION (A-H,O-Z)
	DOUBLE PRECISION LSUN,LSTAR,JD,JD0,LST,M1,LATITUDE,LONGITUDE
	DIMENSION SUMDAY(12)
	DATA PI/3.14159265358979D0/
	DATA SUMDAY/0.,31.,59.,90.,120.,151.,181.,212.,243.,273.
     #,304.,334.0/
	DAYFRACTION(H1,M1,S1)=((S1/60.0D0+M1)/60.D0+H1)/24.0D0

C	Degress to radians factor
	DTOR = PI / 180.D0

C	This quantities are now parameters
C	PARAMETER (CTIOLAT=-30.16606D0, CTIOLONG=70.81489D0)
C	longitude=CTIOLONG
C	latitude=CTIOLAT

	ECL = (23.+(27.+(8.26-0.4684*(YEAR-1900.))/60.)/60.)*PI/180.
	SINDEC = DSIN(DEC)
	COSDEC = DCOS(DEC)
	SB = SINDEC*DCOS(ECL)-COSDEC*DSIN(ECL)*DSIN(RA)
	BSTAR = DASIN(SB)
	CL = DCOS(RA)*COSDEC/DCOS(BSTAR)
	SL = (SINDEC*DSIN(ECL)+COSDEC*DCOS(ECL)*DSIN(RA))/DCOS(BSTAR)
	LSTAR = DACOS(CL)
	IF (SL*CL.GT.0.0D0 .AND. CL.LT.0.0D0) LSTAR = 2.0D0*PI-LSTAR
	IF (SL*CL.LT.0.0D0 .AND. CL.GT.0.0D0) LSTAR = 2.0D0*PI-LSTAR
	IF (MONTH .EQ. 0) THEN
		DAYS = 0.0
	ELSE
		DAYS = SUMDAY(MONTH) + DAY
	END IF
	IY = IDINT(YEAR)
	IF (MONTH.GT.2 .AND. IY-4*(IY/4).EQ.0) DAYS = DAYS + 1.0D0
	NY = INT(YEAR-1900.D0)
	NLEAP = (NY-1)/4
	XJD = 365.0D0*DBLE(NY)+DBLE(NLEAP)+DAYS+UT/24.0D0
	JD = XJD+2415019.5D0
C***	Formulae from Astronomical Almanac (1986) C24
	

C***	LSUN = Mean longitude of the sun
	E = JD - 2451545.0D0
	LSUN = 280.460D0 + 0.9856474D0*E
	LSUN = DMOD(LSUN,360.0D0)
	IF (LSUN.LT.0.0D0) LSUN=LSUN+360.0D0

C**	GSUN = Mean anomaly of the sun
	GSUN = 357.528D0 + 0.9856003D0*E
	GSUN = DMOD(GSUN,360.0D0)
	IF (GSUN.LT.0.0D0) GSUN=GSUN+360.0D0
C***	Convert to true anomaly via equation of center
	LSUN = LSUN+ 1.915D0*DSIN(GSUN*DTOR) +
     *         0.020D0 * DSIN( 2.0D0 * GSUN * DTOR )
	LSUN = PI*LSUN/180.0D0
	A = 1.4955608D8/(1.0D0+0.016719D0*DCOS(LSUN-4.938032374D0))
	DT = -A*DCOS(BSTAR)*DCOS(LSTAR-LSUN)/2.997925D5
	HJD = JD+DT/86400.D0

C***	Compute local siderial time in fractions of a day using the relation
C***	LST = GMST+UT*C-HL  where
C***	GMST = Greenwich mean siderial time at 0h UT ( 0.5 fraction of a 
C***	      JD
C***	C  = 1.0027379
C***	HL = longitude of OBSERVATORY
c	Formulae from Astronomical Almanac (1986) B6

	HL = LONGITUDE/360.0D0
	JD0=DINT(JD+0.5D0) - 0.5D0
	TU = (JD0 - 2451545.0D0)/36525.0D0
	GMST = 24110.54841D0 + 8640184.812866D0*TU + 0.093104D0*TU*TU
     *         - 6.2D-6*TU*TU*TU
	GMST = DMOD(GMST,86400.0D0)
	IF (GMST.LT.0.0D0) GMST=GMST+86400.0D0
	GMST=GMST/86400.0D0
	LST = GMST + (UT/24.0D0)*1.00273790934D0 -HL
	LST = DMOD(LST,1.0D0)*2.0D0*PI
	IF (LST .LT. 0.0D0) LST = 2.0D0*PI+LST
	HA = LST-RA
C***	Compute zenith distance and airmass
C	SINLAT = DSIN(PI*(37.0D0 + 20.0D0/60.D0 + 25.3D0/3600.D0)/180.0D0)
	SINLAT = DSIN(PI*LATITUDE/180.0D0)
	COSLAT = DCOS(PI*LATITUDE/180.D0)
	COSZ = SINLAT*SINDEC+COSLAT*COSDEC*DCOS(HA)
	Z = DACOS(COSZ)
	SECZ = 1.0D0/COSZ
	AIRMAS = SECZ-0.0018167D0*(SECZ-1.0D0) -
     *           0.002875D0 * ( (SECZ-1.0D0) ** 2 )
C***	Compute heliocentric RV correction
c
c...this is from the vis viva eqn. It is not quite correct since
c....it assumes that the motion is perpendicular to the radius vector
c
c	V = 1.326663D11*(2.0D0/A-6.684585813D-9)
c	V = DSQRT(V)*DCOS(BSTAR)*DSIN(LSUN-LSTAR)
c	V = V-0.399D0*COSDEC*DSIN(HA)

c
c...use the v correction given by Smart, p.215
c...pomega is the longitude of perhelion, which is -180 from the
c....longitude of perigee, taken from the Explanatory Supp.
c
	tu=(jd-2415020.0d0)/36525.0d0
	pomega=101.220844d0+1.71918d0*tu
	hp=29.78890d0
	eccen=0.016720d0
	pomega=pi*pomega/180.0d0
	corr=hp*dcos(bstar)*dsin(lsun-lstar)
	corr=corr-hp*eccen*dcos(bstar)*dsin(pomega-lstar)
	v = corr-0.4651d0*coslat*cosdec*dsin(ha)

	RETURN
	END
c
c..............................................................................
c

