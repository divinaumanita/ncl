C
C	$Id: dashbd1024.f,v 1.1.1.1 1992-04-17 22:34:58 ncargd Exp $
C
      BLOCKDATA DASHBD
C
C DASHBD IS USED TO INITIALIZE VARIABLES IN NAMED COMMON.
C
      COMMON /DASHD1/  ISL,  L,  ISIZE,  IP(100),  NWDSM1,  IPFLAG(100)
     1                 ,MNCSTR, IGP
C
      COMMON /FDFLAG/ IFLAG
C
      COMMON /DFFLAG/ IFSTF2
C
      COMMON /DDFLAG/ IFCFLG
C
      COMMON /DCFLAG/ IFSTFL
C
      COMMON /CFFLAG/ IVCTFG
C
      COMMON /DSAVE3/ IXSTOR,IYSTOR
C
      COMMON /DSAVE4/ IX1,IY1,IX2,IY2
C
      COMMON /DSAVE5/ XSAVE(70), YSAVE(70), XSVN, YSVN, XSV1, YSV1,
     1                SLP1, SLPN, SSLP1, SSLPN, N, NSEG
C
      COMMON /SMFLAG/ IOFFS
C
      COMMON /DSUP1/ ISKIP
C
C
      COMMON/INTPR/IPAU,FPART,TENSN,NP,SMALL,L1,ADDLR,ADDTB,MLLINE,
     1    ICLOSE
      SAVE
C **********************************************************************
C
C CONSTANT DEPENDING ON THE IMPLEMENTATION OF THE MODEL PICTURE
C
C     LET NXSIZE BE DEFINED JUST AS IN SUBROUTINE REMOVE, NAMELY
C     SUCH THAT  2**NXSIZE = NUMBER OF MODEL PICTURE POINTS IN X- AND
C     Y- DIRECTION. (NXSIZE IS THE RESOLUTION OF THE MODEL PICTURE. THE
C     MODEL PICTURE IS ASSUMED TO BE QUADRATIC.)
C     THEN ISKIP IS DEFINED AS
C         ISKIP = 2**(15-NXSIZE)
C
C     ISKIP IS USED TO SPEED UP THE MARKING OF POINTS IN THE MODEL
C     PICTURE. THE FACT IS USED THAT 1 POINT IN THE MODEL PICTURE
C     REPRESENTS ISKIP*ISKIP METACODE ADDRESS UNITS.
C
C     DATA ISKIP /0/
C     E.G. FOR A 1024 BY 1024 MODEL PICTURE
      DATA ISKIP /32/
C
C **********************************************************************
C
C
C
C
C IFSTFL CONTROLS THAT FRSTD IS CALLED BEFORE VECTD IS CALLED (IN CFVLD)
C WHENEVER DASHDB OR DASHDC HAS BEEN CALLED.
C
      DATA IFSTFL /1/
C
C IVCTFG INDICATES IF VECTD IS BEING CALLED OR LASTD (IN CFVLD)
C
      DATA IVCTFG /1/
C
C IX1,IY1,IX2 AND IY2 ARE USED TO STORE THE NEXT LINE SEGMENT TO BE
C MARKED.
C
      DATA IX1,IY1,IX2,IY2 /0,0,0,0/
C
C ISL IS A FLAG FOR AN ALL SOLID PATTERN (+1) OR AN ALL GAP PATTERN (-1)
C
      DATA ISL /1/
C
C IGP IS AN INTERNAL PARAMETER. IT IS DESCRIBED IN THE DOCUMENTATION
C TO THE DASHED LINE PACKAGE.
C
      DATA IGP /9/
C
C MNCSTR IS THE MAXIMUM NUMBER OF CHARACTERS ALLOWED IN A HOLLERITH
C STRING PASSED TO DASHDB OR DASHDC.
C
      DATA MNCSTR /15/
C
C IOFFS IS AN INTERNAL PARAMETER.
C IOFFS IS USED IN FDVDLD AND DRAWPV.
C
      DATA IOFFS /0/
C
C
C  INTERNAL PARAMETERS
C
      DATA IPAU/3/
      DATA FPART/1./
      DATA TENSN/2.5/
      DATA NP/150/
      DATA SMALL/128./
      DATA L1/70/
      DATA ADDLR/2./
      DATA ADDTB/2./
      DATA MLLINE/384/
      DATA ICLOSE/6/
C
C IFSTF2 IS A FLAG TO CONTROL THAT FRSTD IS CALLED BEFORE VECTD IS
C CALLED (IN SUBROUTINE FDVDLD), WHENEVER DASHDB OR DASHDC
C HAS BEEN CALLED.
C
      DATA IFSTF2 /1/
C
C IFLAG CONTROLS IF LASTD CAN BE CALLED DIRECTLY OR IF IT WAS JUST
C CALLED FROM BY VECTD SO THAT THIS CALL CAN BE IGNORED.
C
      DATA IFLAG /1/
C
C IFCFLG IS THE FIRST CALL FLAG FOR SUBROUTINE DASHDB AND DASHDC.
C  1 = FIRST CALL TO DASHDB OR DASHDC.
C  2 = DASHDB OR DASHDC HAS BEEN CALLED BEFORE.
C
      DATA IFCFLG /1/
C
C IXSTOR AND IYSTOR CONTAIN THE CURRENT PEN POSITION. THEY ARE
C INITIALIZED TO AN IMPOSSIBLE VALUE.
C
      DATA IXSTOR,IYSTOR /-9999,-9999/
C
C SLP1 AND SLPN ARE INITIALIZED TO AVOID THAT THEY ARE PASSED AS ACTUAL
C PARAMETERS FROM FDVDLD TO MSKRV1 WITHOUT BEING DEFINED.
C
      DATA SLP1,SLPN /-9999.,-9999./
C
C
C
      END
