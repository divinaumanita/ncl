C
C	$Id: twtstr.f,v 1.1.1.1 1992-04-17 22:34:36 ncargd Exp $
C
      SUBROUTINE TWTSTR
      CHARACTER *28 TITLE
      COMMON /BLOCK1/ MESG,IDUMMY(500)
      CALL SET(0.,1.,0.,1.,0.,1.,0.,1.,1)
      TITLE(1:28)='DEMONSTRATION PLOT FOR WTSTR'
      CALL WTSTR(0.5,0.9,TITLE(1:28),30,0,0)
      TITLE(1:3)='AND'
      CALL WTSTR(0.5,0.7,TITLE(1:3),30,0,0)
C
C  The WTSTR call replaces the following PWRIT call.
C
      CALL PWRIT(0.5,0.5,'DEMONSTRATION PLOT FOR PWRIT',28,30,0,0)
      CALL FRAME
      WRITE(MESG,740)
  740 FORMAT(' TWTSTR EXITED--SEE PLOT TO VERIFY PERFORMANCE')
      RETURN
      END
