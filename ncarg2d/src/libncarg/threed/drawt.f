C
C	$Id: drawt.f,v 1.1.1.1 1992-04-17 22:31:48 ncargd Exp $
C
      SUBROUTINE DRAWT (IXA,IYA,IXB,IYB)
      SAVE
      CALL PLOTIT(32*IXA,32*IYA,0)
      IIX = 32*IXB
      IIY = 32*IYB
      CALL PLOTIT(IIX,IIY,1)
C
C     FLUSH PLOTIT BUFFER
C
      CALL PLOTIT(IIX,IIY,0)
      RETURN
      END
