C
C	$Id: lined.f,v 1.1.1.1 1992-04-17 22:32:41 ncargd Exp $
C
      SUBROUTINE LINED (XA,YA,XB,YB)
C USER ENTRY POINT.
C
      DATA IDUMMY /0/
      CALL FL2INT (XA,YA,IXA,IYA)
      CALL FL2INT (XB,YB,IXB,IYB)
C
      CALL CFVLD (1,IXA,IYA)
      CALL CFVLD (2,IXB,IYB)
      CALL CFVLD (3,IDUMMY,IDUMMY)
C
      RETURN
      END
