      PROGRAM FAGCUCLR
      PARAMETER (NPTS=200)
      PARAMETER (NCURVE=4)
      REAL YDRA(NPTS,NCURVE),XDRA(NPTS)

      DO 10 I=1,NPTS
	 XDRA(I  )=I*0.1
	 DO 10 J=1,NCURVE
            YDRA(I,J)=SIN(XDRA(I)+0.2*J)*EXP(-0.01*XDRA(I)*J**2)
  10  CONTINUE

      CALL OPNGKS

      CALL DEFCLR

      CALL EZMXY (XDRA,YDRA,NPTS,NCURVE,NPTS,'CURVE COLORS$')

      CALL CLSGKS

      STOP
      END

      SUBROUTINE DEFCLR
      CALL GSCR(1, 0, 0.0, 0.0, 0.0)
      CALL GSCR(1, 1, 1.0, 1.0, 1.0)
      CALL GSCR(1, 2, 1.0, 0.0, 0.0)
      CALL GSCR(1, 3, 0.0, 1.0, 0.0)
      CALL GSCR(1, 4, 0.4, 0.7, 0.9)
      CALL GSCR(1, 5, 0.7, 0.4, 0.7)
      CALL GSCR(1, 6, 0.9, 0.7, 0.4)
      CALL GSCR(1, 7, 0.4, 0.9, 0.7)
      RETURN
      END
	
      SUBROUTINE AGCHCU(IFLG,KDSH)
      CALL PLOTIF (0.,0.,2)
      IF (IFLG .EQ. 0) THEN
         CALL GSPLCI( ABS(KDSH)+3 )
         CALL GSTXCI( ABS(KDSH)+3 )
      ELSE
	 CALL GSPLCI(1)
	 CALL GSTXCI(1)
      ENDIF
      RETURN
      END

