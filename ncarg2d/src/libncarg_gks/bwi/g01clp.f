C
C	$Id: g01clp.f,v 1.1.1.1 1992-04-17 22:33:56 ncargd Exp $
C
        SUBROUTINE G01CLP
C
C       PROCESS CLIPPING PARAMETERS.
C
      COMMON /GKSIN1/FCODE,CONT,IL1,IL2,ID(128),RL1,RL2,RX(128),
     - RY(128),STRL1,STRL2,RERR
      COMMON /GKSIN2/STR
      INTEGER FCODE, CONT, IL1, IL2, ID, RL1, RL2
      INTEGER STRL1, STRL2, RERR
      REAL  RX, RY
      CHARACTER*80 STR
      COMMON  /G01WSL/  MWKID   ,MCONID ,MWTYPE ,MSTATE ,MOPEN  ,
     +                  MDEFMO  ,MREGMO ,MDEMPT ,MNFRAM ,MTUS   ,
     +                  RWINDO(4)       ,CWINDO(4)      ,
     +                  RWKVP (4)       ,CWKVP (4)      ,
     +                  MOLMAX  ,MOL    ,MCOVFL ,MCSORT ,MCOLI(256),
     +                  SRED(256)       ,SGREEN(256)    ,SBLUE(256),
     +                  MRCREC(4)       ,MRCLIP
        INTEGER         MWKID   ,MCONID ,MWTYPE ,MSTATE ,MOPEN
        INTEGER         MDEFMO  ,MREGMO ,MDEMPT ,MNFRAM ,MTUS
        INTEGER         MOLMAX  ,MOL    ,MCOVFL ,MCSORT ,MCOLI
        REAL            RWINDO          ,CWINDO
        REAL            RWKVP           ,CWKVP
        REAL            SRED            ,SGREEN         ,SBLUE
        INTEGER         MRCREC  ,MRCLIP
      COMMON  /G01INS/  MCODES  ,MCONTS ,
     +                  MVDCFW  ,MCIXFW ,MDCCFW ,MIXFW  ,MINTFW ,
     +                  MDCCRG  ,MXOFF  ,MXSCAL ,MYOFF  ,MYSCAL ,
     +                  MINXVD  ,MAXXVD ,MINYVD ,MAXYVD ,
     +                  MCFRM   ,MCOPCL ,MCOPID ,MCNBYT ,
     +                  MCCBYT  ,MCFPP  ,MSLFMT ,MEFW   ,MCTCHG ,
     +                  MBCCHG
        INTEGER         MCODES  ,MCONTS
        INTEGER         MVDCFW  ,MCIXFW ,MDCCFW ,MIXFW  ,MINTFW
        INTEGER         MDCCRG  ,MXOFF  ,MXSCAL ,MYOFF  ,MYSCAL
        INTEGER         MINXVD  ,MAXXVD ,MINYVD ,MAXYVD
        INTEGER         MCFRM   ,MCOPCL ,MCOPID ,MCNBYT
        INTEGER         MCCBYT  ,MCFPP  ,MSLFMT ,MEFW   ,MCTCHG
        INTEGER         MBCCHG
C
C  Id code parameters for every element, and class codes for each class.
C
      COMMON /G01OPC/ IDNOOP, IDBEGM, IDENDM, IDBEGP, IDBGPB, IDENDP
      COMMON /G01OPC/ IDMVER, IDMELT, IDDREP, IDCSEL, IDVEXT, IDVINT
      COMMON /G01OPC/ IDCREC, IDCLIN, IDPLIN, IDPMRK, IDTEXT, IDPGON
      COMMON /G01OPC/ IDCARY, IDGDP,  IDLBIX, IDLTYP, IDLWID, IDLCLR
      COMMON /G01OPC/ IDMBIX, IDMTYP, IDMSIZ, IDMCLR, IDTBIX, IDTFON
      COMMON /G01OPC/ IDTPRE, IDCHEX, IDCHSP, IDTCLR, IDCHHT, IDCHOR
      COMMON /G01OPC/ IDTXPA, IDTXAL, IDFBIX, IDINTS, IDFCLR, IDHAIX
      COMMON /G01OPC/ IDPTIX, IDFRPT, IDPTBL, IDPTSZ, IDCTBL, IDASFS
      COMMON /G01OPC/ IDESC,  IDMESS, IDAPLD, IDBKGC, IDDSCR, IDFLST
      COMMON /G01OPC/ CLDELM, CLMDES, CLPDES, CLCNTL, CLPRIM, CLPRAT
      COMMON /G01OPC/ CLESCE, CLEXTE
C
C  Parameter data types.
C
      INTEGER         IDNOOP, IDBEGM, IDENDM, IDBEGP, IDBGPB, IDENDP
      INTEGER         IDMVER, IDMELT, IDDREP, IDCSEL, IDVEXT, IDVINT
      INTEGER         IDCREC, IDCLIN, IDPLIN, IDPMRK, IDTEXT, IDPGON
      INTEGER         IDCARY, IDGDP,  IDLBIX, IDLTYP, IDLWID, IDLCLR
      INTEGER         IDMBIX, IDMTYP, IDMSIZ, IDMCLR, IDTBIX, IDTFON
      INTEGER         IDTPRE, IDCHEX, IDCHSP, IDTCLR, IDCHHT, IDCHOR
      INTEGER         IDTXPA, IDTXAL, IDFBIX, IDINTS, IDFCLR, IDHAIX
      INTEGER         IDPTIX, IDFRPT, IDPTBL, IDPTSZ, IDCTBL, IDASFS
      INTEGER         IDESC,  IDMESS, IDAPLD, IDBKGC, IDDSCR, IDFLST
      INTEGER         CLDELM, CLMDES, CLPDES, CLCNTL, CLPRIM, CLPRAT
      INTEGER         CLESCE, CLEXTE
C
C Class code parameters for every element.
C
      INTEGER         CLNOOP, CLBEGM, CLENDM, CLBEGP, CLBGPB, CLENDP
      INTEGER         CLMVER, CLMELT, CLDREP, CLCSEL, CLVEXT, CLVINT
      INTEGER         CLCREC, CLCLIN, CLPLIN, CLPMRK, CLTEXT, CLPGON
      INTEGER         CLCARY, CLGDP,  CLLBIX, CLLTYP, CLLWID, CLLCLR
      INTEGER         CLMBIX, CLMTYP, CLMSIZ, CLMCLR, CLTBIX, CLTFON
      INTEGER         CLTPRE, CLCHEX, CLCHSP, CLTCLR, CLCHHT, CLCHOR
      INTEGER         CLTXPA, CLTXAL, CLFBIX, CLINTS, CLFCLR, CLHAIX
      INTEGER         CLPTIX, CLFRPT, CLPTBL, CLPTSZ, CLCTBL, CLASFS
      INTEGER         CLESC,  CLMESS, CLAPLD, CLBKGC, CLDSCR, CLFLST
C
C  Equivalence all individual class code parameters to the single
C  code for the class in which the element(s) belong.
C
      EQUIVALENCE (CLDELM, CLNOOP,CLBEGM,CLENDM,CLBEGP,CLBGPB,CLENDP)
      EQUIVALENCE (CLMDES, CLMVER,CLMELT,CLDREP,CLDSCR,CLFLST)
      EQUIVALENCE (CLPDES, CLCSEL,CLVEXT,CLBKGC)
      EQUIVALENCE (CLCNTL, CLVINT,CLCREC,CLCLIN)
      EQUIVALENCE (CLPRIM, CLPLIN,CLPMRK,CLTEXT,CLPGON,CLCARY,CLGDP)
      EQUIVALENCE (CLPRAT, CLLBIX,CLLTYP,CLLWID,CLLCLR,CLMBIX,CLMTYP)
      EQUIVALENCE (CLPRAT, CLMSIZ,CLMCLR,CLTBIX,CLTFON,CLTPRE,CLCHEX)
      EQUIVALENCE (CLPRAT, CLCHSP,CLTCLR,CLCHHT,CLCHOR,CLTXPA,CLTXAL)
      EQUIVALENCE (CLPRAT, CLFBIX,CLINTS,CLFCLR,CLHAIX,CLPTIX,CLFRPT)
      EQUIVALENCE (CLPRAT, CLPTBL,CLPTSZ,CLCTBL,CLASFS)
      EQUIVALENCE (CLESCE, CLESC), (CLEXTE, CLMESS,CLAPLD)
C
        INTEGER  NBYTES, I
        LOGICAL  CHANGE
C
C     IF CLIPPING INDICATOR HAS CHANGED, SEND IT AND STORE IT IN WSL.
C
        IF (ID(1).NE.MRCLIP)  THEN
           MRCLIP = ID(1)
C
C          PUT OUT OPCODE (CLASS AND ID) AND LENGTH
           NBYTES = 1+(MEFW-1)/8
C                   CLASS,ID, LENGTH
           CALL GPUTNI (CLCLIN, IDCLIN, NBYTES, RERR)
           IF (RERR.NE.0)  RETURN
C
C          PUT OUT CLIPPING INDICATOR PARAMETER.
C                         DATA, PRECIS, COUNT
           CALL GPUTPR (MRCLIP, MEFW,     1, RERR)
           IF (RERR.NE.0)  RETURN
        END IF
C
C     NORMALIZE CLIPPING RECTANGLE, SEND AND STORE IT IF CHANGED.
C
C       NORMALIZE NDC LIMITS OF RECTANGLE (ASSUME BOUNDS CHECK
C       ABOVE WSI), STORE AS RECTANGLE CORNER POINTS.
        ID(1) = MXOFF + MXSCAL*RX(1)
        ID(3) = MXOFF + MXSCAL*RX(2)
        ID(2) = MYOFF + MYSCAL*RY(1)
        ID(4) = MYOFF + MYSCAL*RY(2)
        CHANGE = .FALSE.
        DO 10 I=1,4
           IF (ID(I).NE.MRCREC(I))  THEN
              CHANGE = .TRUE.
              MRCREC(I) = ID(I)
           END IF
10      CONTINUE
        IF (CHANGE)  THEN
C
C          TOTAL BYTE LENGTH, BASED ON VDC BIT PRECISION.
           NBYTES = 1 + (4*MVDCFW-1)/8
C
C          PUT OUT OPCODE (CLASS AND ID) AND LENGTH.
C                   CLASS, ID, LENGTH
           CALL GPUTNI (CLCREC, IDCREC, NBYTES, RERR)
           IF (RERR.NE.0)  RETURN
C
C          PUT OUT CLIPPING RECTANGLE CORNER POINTS.
C                         DATA, PRECIS, COUNT
           CALL GPUTPR (MRCREC, MVDCFW,     4, RERR)
        END IF
C
C
        RETURN
C
        END
