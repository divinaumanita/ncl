      PROGRAM FAGEZMXY
      PARAMETER (NPTS=200)
      PARAMETER (NCURVE=4)
      REAL YDRA(NPTS,NCURVE),XDRA(NPTS)

      DO 10 I=1,NPTS
	 XDRA(I  )=I*0.1
	 DO 10 J=1,NCURVE
            YDRA(I,J)=SIN(XDRA(I)+0.2*J)*EXP(-0.01*XDRA(I)*J**2)
  10  CONTINUE

      CALL OPNGKS
      CALL EZMXY (XDRA,YDRA,NPTS,NCURVE,NPTS,'EZMXY$')
      CALL CLSGKS

      STOP
      END
