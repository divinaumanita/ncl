C
C	$Id: mapconvrt.f,v 1.1.1.1 1992-04-17 22:35:25 ncargd Exp $
C
      PROGRAM CONVRT
        DIMENSION FLIM(4),PNTS(200)
        OPEN (UNIT=1,STATUS='OLD',FILE='ezmapdat',ERR=5)
        OPEN (UNIT=2,STATUS='NEW',FORM='UNFORMATTED',FILE='ezmapdata',
     +      ERR=6)
        REWIND 1
        REWIND 2
    1   READ (1,3,END=2) NPTS,IGID,IDLS,IDRS,(FLIM(I),I=1,4)
        IF (NPTS.GT.1) READ (1,4,END=2) (PNTS(I),I=1,NPTS)
        WRITE (2) NPTS,IGID,IDLS,IDRS,(FLIM(I),I=1,4),(PNTS(I),I=1,NPTS)
        GO TO 1
    2   STOP
    3   FORMAT (4I4,4F8.3)
    4   FORMAT (10F8.3)
    5   WRITE (6,*) 'Error in opening the file <ezmapdat>.'
        STOP
    6   WRITE(6,*) 'Error in creating the file <ezmapdata>.'
        STOP
      END
