C
C	$Id: psym3.f,v 1.1.1.1 1992-04-17 22:31:47 ncargd Exp $
C
      SUBROUTINE PSYM3 (U,V,W,ICHAR,SIZE,IDIR,ITOP,IUP)
      SAVE
C
C THE FOLLOWING CALL IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR
C
      CALL Q8QST4 ('GRAPHX','THREED','PSYM3','VERSION  1')
      IF (IUP .EQ. 2) CALL VECT3 (U,V,W)
      CALL PWRZ (U,V,W,ICHAR,1,SIZE,IDIR,ITOP,0)
      RETURN
      END
