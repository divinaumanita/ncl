C
C	$Id: intzs.f,v 1.1.1.1 1992-04-17 22:31:38 ncargd Exp $
C
      SUBROUTINE INTZS (XX,YY,ZZ,LIN3,ITOP)
C
C FORCE STORAGE OF X, Y, AND Z INTO COMMON BLOCK
C
      COMMON /PWRZ2S/ X, Y, Z
      DATA IDUMX,IDUMY,IDUMZ /0, 0, 0/
      X = XX
      Y = YY
      Z = ZZ
      CALL INITZS (IDUMX,IDUMY,IDUMZ,LIN3,ITOP,1)
      RETURN
      END
