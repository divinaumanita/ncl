C
C	$Id: ezvec.f,v 1.1.1.1 1992-04-17 22:31:50 ncargd Exp $
C
      SUBROUTINE EZVEC (U,V,M,N)
C
C THIS SUBROUTINE IS FOR THE USER WHO WANTS A QUICK-AND-DIRTY VECTOR
C PLOT WITH DEFAULT VALUES FOR MOST OF THE ARGUMENTS.
C
        SAVE
C
      DIMENSION       U(M,N)     ,V(M,N)     ,SPVAL(2)
C
      DATA FLO,HI,NSET,LENGTH,ISPV,SPVAL(1),SPVAL(2) /
     +      0.,0.,   0,     0,   0,      0.,      0. /
C
C THE FOLLOWING CALL IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR.
C
      CALL Q8QST4 ('CRAYLIB','VELVCT','EZVEC','VERSION  6')
C
      CALL VELVCT (U,M,V,M,M,N,FLO,HI,NSET,LENGTH,ISPV,SPVAL)
      CALL FRAME
      RETURN
      END
