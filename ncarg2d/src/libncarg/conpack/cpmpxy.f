C
C	$Id: cpmpxy.f,v 1.1.1.1 1992-04-17 22:32:45 ncargd Exp $
C
C
C-----------------------------------------------------------------------
C
      SUBROUTINE CPMPXY (IMAP,XINP,YINP,XOTP,YOTP)
C
C By default, CONPACK draws contour lines using X coordinates in the
C range from XAT1 to XATM and Y coordinates in the range from YAT1 to
C YATN.  Setting the flag 'MAP' non-zero causes those coordinates to be
C transformed by calling the subroutine CPMPXY.  By default, 'MAP' = 1
C selects the EZMAP transformations and 'MAP' = 2 selects the polar
C coordinate transformations.  The user of CONPACK may replace this
C subroutine as desired to transform the final coordinates and thus to
C transform the objects drawn.
C
C NOTE:  As of 4/25/91, this routine calls a new EZMAP routine, called
C MAPTRA, instead of MAPTRN.  The new routine returns 1.E12 for points
C which project outside the EZMAP perimeter.
C
C NOTE:  As of 1/14/92, this routine is being changed so that, when IMAP
C is negated, the inverse mapping is requested:  (XINP,YINP) is a point
C in the current user coordinate system; (XOTP,YOTP) is returned and is
C the point which would be carried into (XINP,YINP) by the mapping
C numbered ABS(IMAP).
C
C An additional convention has been adopted which will allow CONPACK to
C find out whether a given inverse transformation is available.  A call
C of the form
C
C       CALL CPMPXY (0,REAL(IMAP),RFLG,DUM1,DUM2)
C
C will return information in RFLG about the mapping numbered IMAP, as
C follows:
C
C   RFLG       forward mapping defined      inverse mapping defined
C   ----       -----------------------      -----------------------
C    0.                 no                            no
C    1.                yes                            no
C    2.                 no                           yes
C    3.                yes                           yes
C
C Versions of CPMPXY that have not been updated to include these new
C features should continue to work for a period of time, but ought to
C be updated eventually.
C
      IF (IMAP.EQ.0) THEN
        IF (INT(XINP).GE.1.AND.INT(XINP).LE.3) THEN
          YINP=3.
        ELSE
          YINP=0.
        END IF
C
C Handle the EZMAP case ...
C
      ELSE IF (ABS(IMAP).EQ.1) THEN
        IF (IMAP.GT.0) THEN
          CALL MAPTRA (YINP,XINP,XOTP,YOTP)
        ELSE
          CALL MAPTRI (XINP,YINP,YOTP,XOTP)
        END IF
C
C ... the polar coordinate case ...
C
      ELSE IF (ABS(IMAP).EQ.2) THEN
        IF (IMAP.GT.0) THEN
          XOTP=XINP*COS(.017453292519943*YINP)
          YOTP=XINP*SIN(.017453292519943*YINP)
        ELSE
          XOTP=SQRT(XINP*XINP+YINP*YINP)
          YOTP=57.2957795130823*ATAN2(YINP,XINP)
        END IF
C
C ... and everything else.
C
      ELSE
        XOTP=XINP
        YOTP=YINP
      END IF
C
C Done.
C
      RETURN
C
      END
