C
C	$Id: entsr.f,v 1.1.1.1 1992-04-17 22:32:36 ncargd Exp $
C
      SUBROUTINE ENTSR(IROLD,IRNEW)
C
C  THIS ROUTINE RETURNS IROLD = LRECOV AND SETS LRECOV = IRNEW.
C
C  IF THERE IS AN ACTIVE ERROR STATE, THE MESSAGE IS PRINTED
C  AND EXECUTION STOPS.
C
C  IRNEW = 0 LEAVES LRECOV UNCHANGED, WHILE
C  IRNEW = 1 GIVES RECOVERY AND
C  IRNEW = 2 TURNS RECOVERY OFF.
C
C  ERROR STATES -
C
C    1 - ILLEGAL VALUE OF IRNEW.
C    2 - CALLED WHILE IN AN ERROR STATE.
C
C
      LOGICAL TEMP
      IF (IRNEW.LT.0 .OR. IRNEW.GT.2)
     1   CALL SETER(' ENTSR - ILLEGAL VALUE OF IRNEW',1,2)
C
      TEMP = IRNEW.NE.0
      IROLD = I8SAV(2,IRNEW,TEMP)
C
C  IF HAVE AN ERROR STATE, STOP EXECUTION.
C
      IF (I8SAV(1,0,.FALSE.) .NE. 0) CALL SETER
     1   (' ENTSR - CALLED WHILE IN AN ERROR STATE',2,2)
C
      RETURN
C
      END
