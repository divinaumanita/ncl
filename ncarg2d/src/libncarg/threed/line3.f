C
C	$Id: line3.f,v 1.1.1.1 1992-04-17 22:31:47 ncargd Exp $
C
      SUBROUTINE LINE3 (UA,VA,WA,UB,VB,WB)
      SAVE
C
C THE FOLLOWING CALL IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR
C
      CALL Q8QST4 ('GRAPHX','THREED','LINE3','VERSION  1')
      CALL TRN32T (UA,VA,WA,XA,YA,XDUM,2)
      CALL TRN32T (UB,VB,WB,XB,YB,XDUM,2)
      IIX = 32*IFIX(XB)
      IIY = 32*IFIX(YB)
      CALL PLOTIT (32*IFIX(XA),32*IFIX(YA),0)
      CALL PLOTIT (IIX,IIY,1)
C
C     FLUSH PLOTIT BUFFER
C
      CALL PLOTIT (IIX,IIY,0)
      RETURN
      END
