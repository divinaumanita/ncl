C
C	$Id: intzi.f,v 1.1.1.1 1992-04-17 22:31:36 ncargd Exp $
C
      SUBROUTINE INTZI (XX,YY,ZZ,LIN3,ITOP)
C
C FORCE STORAGE OF X, Y, AND Z INTO COMMON BLOCK
C
      COMMON /PWRZ2I/ X, Y, Z
      DATA IDUMX,IDUMY,IDUMZ /0, 0, 0/
      X = XX
      Y = YY
      Z = ZZ
      CALL INITZI (IDUMX,IDUMY,IDUMZ,LIN3,ITOP,1)
      RETURN
      END
