C
C	$Id: drawi.f,v 1.1.1.1 1992-04-17 22:31:26 ncargd Exp $
C
C
C The subroutine DRAWI.
C --- ---------- ------
C
      SUBROUTINE DRAWI (IXA,IYA,IXB,IYB)
C
C This routine is included for use by PWRZI.
C
      CALL ISPLTF (REAL(IXA)/32767.,REAL(IYA)/32767.,1)
      CALL ISPLTF (REAL(IXB)/32767.,REAL(IYB)/32767.,2)
      RETURN
      END
