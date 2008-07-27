C
C	$Id: xmdef.f,v 1.5 2008-07-27 00:59:05 haley Exp $
C                                                                      
C                Copyright (C)  2000
C        University Corporation for Atmospheric Research
C                All Rights Reserved
C
C The use of this Software is governed by a License Agreement.
C
      SUBROUTINE XMDEF(IOS,STATUS)
C
C  SET ALL THE CURRENT VALUES FOR PARSING AND DISPLAYING TO DEFAULT
C
C  DEFINE THE DEFAULT BUNDLE TABLE ENTRIES TO USE
C
      COMMON/CAPBND/PLBTEC, PLIBTB, PLTBTB, PLWBTB, PLCBTB,
     1              PMBTEC, PMIBTB, PMTBTB, PMSBTB, PMCBTB,
     2              TXBTEC, TXIBTB, TXFBTB, TXPBTB, TCXBTB,
     3              TCSBTB, TXCBTB, FABTEC, FAIBTB, FISBTB,
     4              FASBTB, FACBTB
      INTEGER       TBLSIZ
      PARAMETER (TBLSIZ=6)
      INTEGER PLBTEC,PLIBTB(TBLSIZ),PLTBTB(TBLSIZ),PLCBTB(TBLSIZ),
     1        PMBTEC,PMIBTB(TBLSIZ),PMTBTB(TBLSIZ),PMCBTB(TBLSIZ),
     2        TXBTEC,TXIBTB(TBLSIZ),TXFBTB(TBLSIZ),TXPBTB(TBLSIZ),
     3        TXCBTB(TBLSIZ),FACBTB(TBLSIZ),
     4        FABTEC,FAIBTB(TBLSIZ),FISBTB(TBLSIZ),FASBTB(TBLSIZ)
      REAL PLWBTB(TBLSIZ),PMSBTB(TBLSIZ),TCXBTB(TBLSIZ),TCSBTB(TBLSIZ)
      INTEGER LENBND
      PARAMETER (LENBND=4+18*TBLSIZ)
      COMMON /CAPCOL/ COLINT, COLIDX, IDXCUR, VDMINT, DMPAVL, COLFMT
     1               ,COLFIN, IDXMAX, MSTSTR, MSTSIZ, MTRSTR, DMPMDL
     2               ,MTRSIZ, DMPIDV, DMPFIN, DMPFMT
      INTEGER         MAPMAX, COLMAX, MSTMAX, MTRMAX, DMPMAX
      PARAMETER   (MAPMAX=256, COLMAX=15, MSTMAX=50, MTRMAX=20)
      PARAMETER   (DMPMAX=50)
      INTEGER         COLINT(MAPMAX*3)      , COLIDX(MAPMAX), IDXCUR,
     1                VDMINT, COLFMT(COLMAX,4)      , COLFIN(8)     ,
     2                IDXMAX, MSTSTR(MSTMAX), MSTSIZ, MTRSTR(MTRMAX),
     3                DMPMDL, MTRSIZ, DMPFIN(8)     , DMPFMT(DMPMAX,4)
      LOGICAL         DMPAVL, DMPIDV
      REAL            COLRIN(8),DMPRIN(8)
      INTEGER LENCOL
      PARAMETER   (LENCOL=MAPMAX*3+MAPMAX+1+1+1+COLMAX*4+8+1+MSTMAX+
     1                    1+MTRMAX+1+1+1+8+DMPMAX*4)
      EQUIVALENCE (COLFIN,COLRIN),(DMPFIN,DMPRIN)
      COMMON /CAPSPC/ DUMSPC,ENDDSP
      INTEGER     DUMSIZ,DUMSM1
      PARAMETER (DUMSIZ=327, DUMSM1=DUMSIZ-1)
      INTEGER     DUMSPC(DUMSM1),ENDDSP
      COMMON /CAPDEV/ DGISTR, DGISIZ, DGESTR, DGESIZ, DTISTR,
     1                DTISIZ, DCDLLX, DCDLLY, DCDURX, DCDURY,
     3                DCOAVL, CORFMT, CORFIN, BATCH , DHCSIZ,
     4                DHCSTR, CORXOF, CORYOF, DASBIT, CORXSC,
     5                CORYSC, VDWLLX, VDWLLY, VDWURX, VDWURY
      INTEGER         DGIMAX, DGEMAX, DTIMAX, DCFTMX, DHCMAX
      PARAMETER   (DGIMAX=300, DGEMAX=150, DTIMAX=100)
      PARAMETER   (DCFTMX=30 , DHCMAX=50)
      INTEGER         DGISTR(DGIMAX), DGISIZ, DGESTR(DGEMAX),
     1                DGESIZ, DTISTR(DTIMAX), DTISIZ, DCDLLX,
     2                DCDLLY, DCDURX, DCDURY, CORFMT(DCFTMX,4),
     3                CORFIN(8)     , DHCSIZ, DHCSTR(DHCMAX),
     4                CORXOF, CORYOF, DASBIT, VDWLLX, VDWLLY,
     5                VDWURX, VDWURY
      REAL            CORXSC, CORYSC, CORRIN(8)
      LOGICAL         DCOAVL, BATCH
C  Size of the COMMON
      INTEGER         LENDEV
      PARAMETER   (LENDEV=DGIMAX+1+DGEMAX+1+DTIMAX+1+4+1+4*DCFTMX+
     1                  8+2+DHCMAX+9)
      EQUIVALENCE (CORFIN,CORRIN)
      COMMON/TREROR/ ALLOK, MFRCHK, MTOPER, METRDC, REDERR, TYPCHG
     1             ,INVTYP, MINVLD, TYPERR, FRMEND, ENCINT, IVDCDT
     2             ,GCOERR, GCRERR, GCCERR, FCOERR, FCRERR, FCCERR
     3             ,PLIDXG, PMIDXG, TXIDXG, PGIDXG, INVLMT, CELERR
     4             ,COIERR, COLNRM, UNKNOW, UNKOPC, ENDMTF, VNEROR
     5             ,BADRSZ, DEVOUT, NOVERS, BADFNT, PGMERR, FASERR
     6             ,HINERR, VDWERR, RDWERR, RIXLIM
      INTEGER        ALLOK, MFRCHK, MTOPER, METRDC, REDERR, TYPCHG
     1             ,INVTYP, MINVLD, TYPERR, FRMEND, ENCINT, IVDCDT
     2             ,GCOERR, GCRERR, GCCERR, FCOERR, FCRERR, FCCERR
     3             ,PLIDXG, PMIDXG, TXIDXG, PGIDXG, INVLMT, CELERR
     4             ,COIERR, COLNRM, UNKNOW, UNKOPC, ENDMTF, VNEROR
     5             ,BADRSZ, DEVOUT, NOVERS, BADFNT, PGMERR, FASERR
     6             ,HINERR, VDWERR, RDWERR, RIXLIM
      COMMON /PGKSCOM/ CLPDAT, CLPFLG, POLIDX, LINTYP, LINWTH, LINCOL,
     1                LINRGB, MARIDX, MARSIZ, MARCOL, MARRGB, TXTIDX,
     2                INTSTL, PATIDX, FILCOL, FILRGB, MARTYP, HORIZ ,
     3                VERT  , PATH  , CHIGHT, XU    , YU    , XB    ,
     4                YB    , TXTCOL, FINDEX, CEXPN , CSPACE, CURIDX,
     5                CURIMP, CURINT, COLMOD, FILIDX, TXTRGB, PROPN ,
     6                FIRSTX, FIRSTY, LASTX , LASTY , TRATIO, CBV   ,
     7                CUV   , CHP   , CVP   , CCSPAC, CHHORZ, CDV   ,
     8                PMRSIZ, CLPX  , CLPY  , CLPP  , DEFREP, DEFLEN,
     9                VDCECR, TRANVN, TXTPRE, HATIDX, FILRPT, ASFSRF,
     A                ASFSDF, MAPMOD, VERSOK, PCBFST, CPGLEN, CLPNUL,
     B                MTDLEN
      INTEGER         CMPMAX, ASFMAX
      PARAMETER      (CMPMAX=256    , ASFMAX=18)
      LOGICAL         CLPFLG, PROPN , CHHORZ, DEFREP, CLPNUL, MAPMOD,
     1                VERSOK, PCBFST
      REAL            LINWTH, MARSIZ, CEXPN , CSPACE, TRATIO, CBV(2),
     1                CUV(2), CDV(2), CCSPAC
      INTEGER         CLPDAT(4)     , POLIDX, LINTYP, LINCOL, LINRGB(3),
     1                MARIDX, MARCOL, MARRGB(3)     , TXTIDX, INTSTL,
     2                PATIDX, FILCOL, FILRGB(3)     , MARTYP, HORIZ ,
     3                VERT  , PATH  , XU    , YU    , XB    , YB    ,
     4                TXTCOL, FINDEX, CURIMP(CMPMAX), CURINT(CMPMAX*3),
     5                CHIGHT, COLMOD, FILIDX, TXTRGB(3)     , CURIDX,
     6                FIRSTX, FIRSTY, LASTX , LASTY , CHP   , CVP   ,
     7                PMRSIZ, CLPX  , CLPY  , CLPP  , DEFLEN, TRANVN,
     8                TXTPRE, HATIDX, FILRPT(2)     , VDCECR(4)     ,
     9                ASFSRF(ASFMAX), ASFSDF(ASFMAX), CPGLEN, MTDLEN
      COMMON /GKSCHR/ MTDESC
      CHARACTER*80    MTDESC
      COMMON /TRTYPE/ METMIN, METEXT, METPRT, METHED, MIOPCL, MXOPCL,
     1                MIOPID, MXOPID, ASCDEC, ASCHEX, ASCOCT, BINARY,
     2                GAHNOR, GALEFT, GACENT, GARITE, GAVNOR, GATOP ,
     3                GACAP , GAHALF, GABASE, GABOTT, GRIGHT, GLEFT ,
     4                GUP   ,
     5                GDOWN , CINDEX, CDIRCT, PENUP , PENDN , FLAGVL,
     6                SEPRVL, ASCTEK, TYPRGB, TYPBGR,
     7                TYPHLS, TYPMON, SOLID , DASHED, INVSBL, SOLPAT,
     8                ASFIND, ASFBND, ASFLNT, ASFLNW, ASFLNC, ASFMRT,
     9                ASFMRS, ASFMRC, ASFFIS, ASFFHI, ASFFPI, ASFFCO,
     A                ASFFPT, ASFFPW, ASFFPC, ASFTFI, ASFTPR, ASFTCX,
     B                ASFTCS, ASFTCO, ASCFLT, PHOLLO, PSOLID, PPATTR,
     C                PHATCH, PEMPTY, HHORIZ, HVERTI, HPOSLP, HNESLP,
     D                HHOAVE, HPOANE
      INTEGER         METMIN, METEXT, METPRT, METHED, MIOPCL, MXOPCL,
     1                MIOPID, MXOPID, ASCDEC, ASCHEX, ASCOCT, BINARY,
     2                GAHNOR, GALEFT, GACENT, GARITE, GAVNOR, GATOP ,
     3                GACAP , GAHALF, GABASE, GABOTT, GRIGHT, GLEFT ,
     4                GUP   ,
     5                GDOWN , CINDEX, CDIRCT, PENUP , PENDN , FLAGVL,
     6                SEPRVL, ASCTEK, TYPRGB, TYPBGR,
     7                TYPHLS, TYPMON, SOLID , DASHED, INVSBL, SOLPAT,
     8                ASFIND, ASFBND, ASFLNT, ASFLNW, ASFLNC, ASFMRT,
     9                ASFMRS, ASFMRC, ASFFIS, ASFFHI, ASFFPI, ASFFCO,
     A                ASFFPT, ASFFPW, ASFFPC, ASFTFI, ASFTPR, ASFTCX,
     B                ASFTCS, ASFTCO, ASCFLT, PHOLLO, PSOLID, PPATTR,
     C                PHATCH, PEMPTY, HHORIZ, HVERTI, HPOSLP, HNESLP,
     D                HHOAVE, HPOANE
      COMMON /TRDASH/ PATFLG, DASPAT, PATBIT, DEFPAT, DASHX, DASHY,
     1                PATVDC
      INTEGER DPATSZ, PATSIZ, DFPTSZ
      PARAMETER (DPATSZ=16, PATSIZ=320, DFPTSZ=4)
      INTEGER PATFLG, DASPAT, PATBIT, DEFPAT(DFPTSZ), DASHX,
     1        DASHY, PATVDC
      COMMON /PTRDEFL/ POLIDF, LINTDF, LINWDF, TLNCDF, MARIDF, MARTDF,
     1                MARSDF, TMRCDF, PMRSDF, HORIDF, VERTDF, PATHDF,
     2                CHIGDF, XUDF, YUDF, XBDF, YBDF, TXTIDF, TTXCDF,
     3                FINDDF, CEXPDF, CSPADF, FILIDF, INTSDF, PATIDF,
     4                TFLCDF, CLPDDF, VDCEDF, CLPFDF, HATIDF, FILRDF,
     5                TXTPDF
      LOGICAL CLPFDF
      REAL LINWDF, MARSDF, CEXPDF, CSPADF
      INTEGER VDCEDF(4), CLPDDF(4), POLIDF, LINTDF, TLNCDF, MARIDF,
     1        MARTDF, TMRCDF, PMRSDF, HORIDF, VERTDF, PATHDF, CHIGDF,
     2        XUDF, YUDF, XBDF, YBDF, TXTIDF, TTXCDF, FINDDF, FILIDF,
     3        INTSDF, PATIDF, TFLCDF, HATIDF, FILRDF(2), TXTPDF
      COMMON /TRMACH/ BTSWRD
      INTEGER BTSWRD
C
      INTEGER  II, TLNCOL, TMRCOL, TTXCOL, TFLCOL
      INTEGER  IOS, STATUS
C
C  SET THE COLOR SPECIFICATION MODE TO INDEXED
C
      COLMOD = CINDEX
C
C  SET THE DEFAULT POLYLINE INFORMATION
C
      POLIDX = POLIDF
      LINTYP = LINTDF
      LINWTH = LINWDF
      TLNCOL = TLNCDF
C
C  SET THE DEFAULT LINE PATTERN
C
      CALL PATSET(LINTYP)
C
C  SET THE DEFAULT POLYMARKER INFORMATION
C
      MARIDX = MARIDF
      MARTYP = MARTDF
      MARSIZ = MARSDF
      TMRCOL = TMRCDF
      PMRSIZ = PMRSDF
C
C  SET THE DEFAULT TEXT INFORMATION
C
      HORIZ = HORIDF
      VERT = VERTDF
      PATH = PATHDF
      CHIGHT = CHIGDF
      XU = XUDF
      YU = YUDF
      XB = XBDF
      YB = YBDF
      TXTIDX = TXTIDF
      TTXCOL = TTXCDF
      TXTPRE = TXTPDF
      IF (FINDEX .NE. FINDDF) THEN
        FINDEX = FINDDF
      ENDIF
      CEXPN = CEXPDF
      CSPACE = CSPADF
C
C  SET THE DEFAULT POLYGON INFORMATION
C
      FILIDX = FILIDF
      INTSTL = INTSDF
      HATIDX = HATIDF
      PATIDX = PATIDF
      FILRPT(1) = FILRDF(1)
      FILRPT(2) = FILRPT(2)
      TFLCOL = TFLCDF
C
C  SET THE MAX COLOR TABLE SPACE AVAILABLE
C  THIS DEPENDS ON THE COLOR TABLE IN CAPDEV AND ONE IN TRSTAT AND
C  THE MAX ON THE DEVICE
C
      IF (IDXMAX .GT. CMPMAX) IDXMAX = CMPMAX
C
C  IF THERE IS COLOR TABLE CAPABILITY THEN SET THE DEFAULT COLORS
C
      IF (DMPAVL) THEN
      DO 100 II = 1, IDXMAX*3
        CURINT(II) = COLINT(II)
 100    CONTINUE
      DO 110 II = 1, IDXCUR
        CURIMP(II) = COLIDX(II)
 110    CONTINUE
      END IF
      CURIDX = IDXCUR
C
C  Set the map modified flag
C
      MAPMOD = .TRUE.
C
C  MAP USER INDICIES TO REAL MAP INDICIES
C
        MARCOL = TMRCOL
        DO 120 II = 1, IDXCUR
                IF (CURIMP(II) .EQ. TMRCOL) THEN
                        MARCOL = II - 1
                        GO TO 121
                END IF
 120    CONTINUE
 121    CONTINUE
        FILCOL = TFLCOL
        DO 130 II = 1, CURIDX
                IF (CURIMP(II) .EQ. TFLCOL) THEN
                        FILCOL = II - 1
                        GO TO 131
                END IF
 130    CONTINUE
 131    CONTINUE
        TXTCOL = TTXCOL
        DO 140 II = 1, CURIDX
                IF (CURIMP(II) .EQ. TTXCOL) THEN
                        TXTCOL = II - 1
                        GO TO 141
                END IF
 140    CONTINUE
 141    CONTINUE
        LINCOL = TLNCOL
        DO 150 II = 1, CURIDX
                IF (CURIMP(II) .EQ. TLNCOL) THEN
                        LINCOL = II - 1
                        GO TO 151
                END IF
 150    CONTINUE
 151    CONTINUE
C
C  SET THE CLIP RECTANGLE TO DEFAULT VDC EXTENT AND INDICATOR TO ON
C
      CLPFLG = CLPFDF
      CLPDAT(1) = CLPDDF(1)
      CLPDAT(2) = CLPDDF(2)
      CLPDAT(3) = CLPDDF(3)
      CLPDAT(4) = CLPDDF(4)
C
C  INTERSECT CLIP RECTANGLE WITH VIRTUAL DEVICE WINDOW
C
      IF (VDWLLX.LT.CLPDAT(3) .AND. CLPDAT(1).LT.VDWURX .AND.
     -    VDWLLY.LT.CLPDAT(4) .AND. CLPDAT(2).LT.VDWURY) THEN
        CLPDAT(1) = MAX(CLPDAT(1),VDWLLX)
        CLPDAT(2) = MAX(CLPDAT(2),VDWLLY)
        CLPDAT(3) = MIN(CLPDAT(3),VDWURX)
        CLPDAT(4) = MIN(CLPDAT(4),VDWURY)
        CLPNUL = .FALSE.
      ELSE
        CLPNUL = .TRUE.
      ENDIF
C
C  SET THE DEFAULT VDC EXTENT
C
      VDCECR(1) = VDCEDF(1)
      VDCECR(2) = VDCEDF(2)
      VDCECR(3) = VDCEDF(3)
      VDCECR(4) = VDCEDF(4)
C
C  SET THE ASPECT SOURCE FLAGS
C
      DO 160 II=1,ASFMAX
        ASFSRF(II) = ASFSDF(II)
 160  CONTINUE
C
      RETURN
      END
