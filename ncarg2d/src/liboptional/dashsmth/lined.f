C
C	$Id: lined.f,v 1.1.1.1 1992-04-17 22:35:11 ncargd Exp $
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
C
C------REVISION HISTORY
C
C JUNE 1984          CONVERTED TO FORTRAN77 AND GKS
C
C DECEMBER 1979      ADDED REVISION HISTORY AND STATISTICS
C                    CALL
C
C JUNE 1988          CHANGED THE NAME OF A COMMON BLOCK TO GET RID OF A
C                    WARNING FROM SEGLDR.  (DJK)
C
C NOVEMBER 1988      REMOVED KURV1S AND KURV2S.  IMPLEMENTED CALLS TO
C                    MSKRV1 AND MSKRV2 INSTEAD.
C
C-----------------------------------------------------------------------
C
      END
