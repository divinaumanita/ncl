C
C	$Id: gqgdp.f,v 1.1.1.1 1992-04-17 22:33:43 ncargd Exp $
C
      SUBROUTINE GQGDP(WTYPE,GDP,ERRIND,NBND,BNDL)
C
C  Details on all GKS COMMON variables are in the GKS BLOCKDATA.
      COMMON/GKINTR/ NOPWK , NACWK , WCONID, NUMSEG,
     +               SEGS(100)     , CURSEG
      INTEGER        NOPWK , NACWK , WCONID, NUMSEG, SEGS  , CURSEG
      COMMON/GKOPDT/ OPS   , KSLEV , WK    , LSWK(2)       ,
     +               MOPWK , MACWK , MNT
      INTEGER        OPS   , WK
      COMMON/GKSTAT/ SOPWK(2)      , SACWK(1)      , CPLI  , CLN   ,
     +               CLWSC , CPLCI , CLNA  , CLWSCA, CPLCIA, CPMI  ,
     +               CMK   , CMKS  , CPMCI , CMKA  , CMKSA , CPMCIA,
     +               CTXI  , CTXFP(2)      , CCHXP , CCHSP , CTXCI ,
     +               CTXFPA, CCHXPA, CCHSPA, CTXCIA, CCHH  , CCHUP(2),
     +               CTXP  , CTXAL(2)      , CFAI  , CFAIS , CFASI ,
     +               CFACI , CFAISA, CFASIA, CFACIA, CPA(2), CPARF(2),
     +               CNT   , LSNT(2)       , NTWN(2,4)     , NTVP(2,4),
     +               CCLIP , SWKTP(2)      , NOPICT, NWKTP , MODEF
      INTEGER        SOPWK , SACWK , CPLI  , CLN   , CPLCI , CLNA  ,
     +               CLWSCA, CPLCIA, CPMI  , CMK   , CPMCI , CMKA  ,
     +               CMKSA , CPMCIA, CTXI  , CTXFP , CTXCI , CTXFPA,
     +               CCHXPA, CCHSPA, CTXCIA, CTXP  , CTXAL , CFAI  ,
     +               CFAIS , CFASI , CFACI , CFAISA, CFASIA, CFACIA,
     +               CNT   , LSNT  , CCLIP , SWKTP , NOPICT, NWKTP ,
     +               MODEF
      REAL           NTWN  , NTVP
      COMMON/GKEROR/ ERS   , ERF
      COMMON/GKENUM/ GBUNDL, GINDIV, GGKCL , GGKOP , GWSOP , GWSAC ,
     +               GSGOP , GOUTPT, GINPUT, GOUTIN, GWISS , GMO   ,
     +               GMI
      INTEGER        GBUNDL, GINDIV, GGKCL , GGKOP , GWSOP , GWSAC ,
     +               GSGOP , GOUTPT, GINPUT, GOUTIN, GWISS , GMO   ,
     +               GMI   , ERS   , ERF
      COMMON/GKSNAM/ GNAM(109)
      CHARACTER*6    GNAM
      COMMON/GKSIN1/ FCODE , CONT  , IL1   , IL2   , ID(128)       ,
     +               RL1   , RL2   , RX(128)       , RY(128)       ,
     +               STRL1 , STRL2 , RERR
      COMMON/GKSIN2/ STR
      INTEGER        FCODE , CONT  , RL1   , RL2   , STRL1 , STRL2 ,
     +               RERR
      CHARACTER*80   STR
C
      INTEGER WTYPE,GDP,ERRIND,NBND,BNDL(4)
C     CHECK IF GKS IS IN PROPER STATE
      CALL GZCKST(8,-1,ERRIND)
      IF (ERRIND .NE. 0) GOTO 100
C     CHECK THAT THE WORKSTATION TYPE IS VALID
      CALL GZCKWK(22,-1,IDUM,WTYPE,ERRIND)
      IF (ERRIND .NE. 0) GO TO 100
C     INVOKE INTERFACE
      FCODE = -113
      CONT  = 0
      IL1   = 2
      IL2   = 2
      ID(1) = WTYPE
      ID(2) = GDP
      CALL GZTOWK
      IF (RERR.NE.0) THEN
      ERRIND = RERR
      GOTO 100
      ENDIF
      NBND    = ID(3)
      BNDL(1) = ID(4)
      BNDL(2) = ID(5)
      BNDL(3) = ID(6)
      BNDL(4) = ID(7)
      RETURN
  100 CONTINUE
      NBND    = -1
      BNDL(1) = -1
      BNDL(2) = -1
      BNDL(3) = -1
      BNDL(4) = -1
      RETURN
      END
