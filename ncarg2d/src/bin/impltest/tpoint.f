C
C	$Id: tpoint.f,v 1.1.1.1 1992-04-17 22:34:37 ncargd Exp $
C
      SUBROUTINE TPOINT
      COMMON /BLOCK1/ MESG,IDUMMY(500)
      CALL SET(0.,1.,0.,1.,0.,1.,0.,1.,1)
      CALL WTSTR(0.5,0.91,'DEMONSTRATION PLOT FOR POINT',20,0,0)
      DO 120 I=1,512
      IX = I*2
      IY = I*2
      CALL POINT(FLOAT(IX)/1024.,FLOAT(IY)/1024.)
      IY = 1024-IY
      CALL POINT(FLOAT(IX)/1024.,FLOAT(IY)/1024.)
  120 CONTINUE
      CALL FRAME
      WRITE(MESG,720)
  720 FORMAT(' TPOINT EXITED--SEE PLOT TO VERIFY PERFORMANCE')
      RETURN
      END
