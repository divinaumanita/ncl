C
C	$Id: gputpr.f,v 1.1.1.1 1992-04-17 22:34:01 ncargd Exp $
C
      SUBROUTINE GPUTPR (BUFFER,BITS,COUNT,GKSERR)
C
C  PUT THE OPERAND STRING INTO THE METAFILE BUFFER
C
C  INPUT
C       BUFFER-LIST OF OPERANDS TO MOVE
C       BITS-PRECISION OF THE OPERANDS
C       COUNT-NUMBER OF OPERANDS IN THE BUFFER
C  OUTPUT
C       GKSERR-ERROR STATUS
C
C  ALL DATA IS TYPE INTEGER UNLESS OTHERWISE INDICATED
C
      IMPLICIT INTEGER (A-Z)
      DIMENSION BUFFER(*)
C
C  OPERAND AND INSTRUCTION COMMUNICATION
C
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
      DATA ALLOK /0/
C
      CTEMP = COUNT
      STRT = 1
C
 10   CONTINUE
C
C  DETERMINE THE NUMBER OF OPERAND WORDS LEFT IN THE CURRENT PARTITION
C
      WCBYT = (MCCBYT*8)/BITS
C
C  COMPUTE AND MOVE THE ALLOWED NUMBER OF OPERANDS
C
      MOVIT = MIN0(WCBYT,CTEMP)
      CALL GMFLOD(BUFFER(STRT),BITS,MOVIT,GKSERR)
      IF (GKSERR .NE. ALLOK) RETURN
C
C  CHECK IF ANOTHER PARTITION HAS TO BE STARTED
C
      CTEMP = CTEMP - MOVIT
      MCCBYT = MCCBYT - (MOVIT*BITS)/8
      IF (CTEMP .NE. 0) THEN
C
C       NEW PARTITION REQUIRED SO SET UP THE INSTRUCTION
C
        STRT = STRT + MOVIT
C       TAKE REMAINDER OF BYTES LEFT IN CURRENT PARTITION (THEY MUST BE USED)
        TCBYT = MCNBYT + MCCBYT
        CALL GMPART(TCBYT,GKSERR)
        IF (GKSERR .NE. ALLOK) RETURN
C
C       MOVE MORE OPERANDS INTO NEW PARTITION
C
        GO TO 10
      END IF
C
      RETURN
      END
