      PROGRAM FAGEZY
      PARAMETER (NPTS=200)
      REAL YDRA(NPTS)

      DO 10 I=1,NPTS
         YDRA(I)=SIN(I*0.1)*EXP(-0.01*I*0.1*4)
  10  CONTINUE

      CALL OPNGKS
      CALL EZY (YDRA,NPTS,'EZY$')
      CALL CLSGKS

      STOP
      END
