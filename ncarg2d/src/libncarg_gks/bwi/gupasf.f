C
C	$Id: gupasf.f,v 1.1.1.1 1992-04-17 22:34:02 ncargd Exp $
C
        SUBROUTINE GUPASF
C
C       UPDATE ASPECT SOURCE FLAG CONTEXT.
C
      COMMON /GKSIN1/FCODE,CONT,IL1,IL2,ID(128),RL1,RL2,RX(128),
     - RY(128),STRL1,STRL2,RERR
      COMMON /GKSIN2/STR
      INTEGER FCODE, CONT, IL1, IL2, ID, RL1, RL2
      INTEGER STRL1, STRL2, RERR
      REAL  RX, RY
      CHARACTER*80 STR
      COMMON  /G01ARQ/  MRPLIX  ,MRLTYP ,ARLWSC ,MRPLCI ,
     +                  MRPMIX  ,MRMTYP ,ARMSZS ,MRPMCI ,
     +                  MRTXIX  ,MRTXP  ,MRTXAL(2)      ,MRCHH  ,
     +                  MRCHOV(4)       ,MRTXFO ,MRTXPR ,ARCHXP ,
     +                  ARCHSP  ,MRTXCI ,
     +                  MRFAIX  ,MRPASZ(4)      ,MRPARF(2)      ,
     +                  MRFAIS  ,MRFASI ,MRFACI ,
     +                  MRASF(13)
        INTEGER         MRPLIX  ,MRLTYP ,MRPLCI
        REAL            ARLWSC
        INTEGER         MRPMIX  ,MRMTYP ,MRPMCI
        REAL            ARMSZS
        INTEGER         MRTXIX  ,MRTXP  ,MRTXAL ,MRTXFO
        INTEGER         MRTXPR  ,MRTXCI ,MRCHH  ,MRCHOV
        REAL            ARCHXP  ,ARCHSP
        INTEGER         MRFAIX  ,MRPASZ ,MRPARF ,MRFAIS ,MRFASI
        INTEGER         MRFACI  ,MRASF
        INTEGER         MRAEQV(45)
        REAL            ARAEQV(45)
        EQUIVALENCE     (MRPLIX, MRAEQV, ARAEQV)
      COMMON  /G01AST/  MSPLIX  ,MSLTYP ,ASLWSC ,MSPLCI ,
     +                  MSPMIX  ,MSMTYP ,ASMSZS ,MSPMCI ,
     +                  MSTXIX  ,MSTXP  ,MSTXAL(2)      ,MSCHH  ,
     +                  MSCHOV(4)       ,MSTXFO ,MSTXPR ,ASCHXP ,
     +                  ASCHSP  ,MSTXCI ,
     +                  MSFAIX  ,MSPASZ(4)      ,MSPARF(2)      ,
     +                  MSFAIS  ,MSFASI ,MSFACI ,
     +                  MSASF(13)
        INTEGER         MSPLIX  ,MSLTYP ,MSPLCI
        REAL            ASLWSC
        INTEGER         MSPMIX  ,MSMTYP ,MSPMCI
        REAL            ASMSZS
        INTEGER         MSTXIX  ,MSTXP  ,MSTXAL ,MSTXFO
        INTEGER         MSTXPR  ,MSTXCI ,MSCHH  ,MSCHOV
        REAL            ASCHXP  ,ASCHSP
        INTEGER         MSFAIX  ,MSPASZ ,MSPARF ,MSFAIS ,MSFASI
        INTEGER         MSFACI  ,MSASF
        INTEGER         MSAEQV(45)
        REAL            ASAEQV(45)
        EQUIVALENCE     (MSPLIX, MSAEQV, ASAEQV)
      COMMON  /G01ADC/  VALCHG(37)      ,ANYASF ,AGPEND(4)      ,
     +                  IVPLIX  ,IVLTYP ,IVLWSC ,IVPLCI ,IVPMIX ,
     +                  IVMTYP  ,IVMSZS ,IVPMCI ,IVTXIX ,IVTXP  ,
     +                  IVTXAL  ,IVCHH  ,IVCHOV ,IVTXFO ,IVTXPR ,
     +                  IVCHXP  ,IVCHSP ,IVTXCI ,IVFAIX ,IVPASZ ,
     +                  IVPARF  ,IVFAIS ,IVFASI ,IVFACI ,IVASF  ,
     +                  IP2AEA(26)      ,IL2AEA(26)     ,
     +                  IALTYP  ,IALWSC ,IAPLCI ,IAMTYP ,IAMSZS ,
     +                  IAPMCI  ,IATXFP ,IACHXP ,IACHSP ,IATXCI ,
     +                  IAFAIS  ,IAFASI ,IAFACI ,
     +                  NCGASF  ,NGKASF ,MASMAP(18)
        LOGICAL         VALCHG  ,ANYASF ,AGPEND
        INTEGER         IVPLIX  ,IVLTYP ,IVLWSC ,IVPLCI ,IVPMIX
        INTEGER         IVMTYP  ,IVMSZS ,IVPMCI ,IVTXIX ,IVTXP
        INTEGER         IVTXAL  ,IVCHH  ,IVCHOV ,IVTXFO ,IVTXPR
        INTEGER         IVCHXP  ,IVCHSP ,IVTXCI ,IVFAIX ,IVPASZ
        INTEGER         IVPARF  ,IVFAIS ,IVFASI ,IVFACI ,IVASF
        INTEGER         IP2AEA  ,IL2AEA
        INTEGER         IALTYP  ,IALWSC ,IAPLCI ,IAMTYP ,IAMSZS
        INTEGER         IAPMCI  ,IATXFP ,IACHXP ,IACHSP ,IATXCI
        INTEGER         IAFAIS  ,IAFASI ,IAFACI
        INTEGER         NCGASF  ,NGKASF ,MASMAP
C
        LOGICAL         ASFCHG(13)
        EQUIVALENCE     (VALCHG(25),ASFCHG(1))
C
C
        INTEGER  I
C
C     COMPUTE CHANGE FLAGS FOR EACH GKS ASF,
C     COMPUTE AGGREGATE AS WELL.
C
        ANYASF = .FALSE.
        DO 435 I=1,NGKASF
           MRASF(I) = ID(I)
           ASFCHG(I) = MRASF(I).NE.MSASF(I)
           ANYASF = ANYASF .OR. ASFCHG(I)
435     CONTINUE
C
C     COMPUTE POLYLINE AGGREGRATE VARIABLE.
C       (NOTE THAT LOGIC RELIES ON ASF POINTERS BEING
C       A CONTIGUOUS SEQUENCE!!)
C
        DO 436 I=IALTYP,IAPLCI
           AGPEND(1) = AGPEND(1) .OR. ASFCHG(I)
436     CONTINUE
C
C     COMPUTE POLYMARKER AGGREGRATE VARIABLES.
C       (NOTE THAT LOGIC RELIES ON ASF POINTERS BEING
C       A CONTIGUOUS SEQUENCE!!)
C
        DO 437 I=IAMTYP,IAPMCI
           AGPEND(2) = AGPEND(2) .OR. ASFCHG(I)
437     CONTINUE
C
C     COMPUTE TEXT AGGREGRATE VARIABLES.
C       (NOTE THAT LOGIC RELIES ON ASF POINTERS BEING
C       A CONTIGUOUS SEQUENCE!!)
C
        DO 438 I=IATXFP,IATXCI
           AGPEND(3) = AGPEND(3) .OR. ASFCHG(I)
438     CONTINUE
C
C     COMPUTE FILL AREA AGGREGRATE VARIABLES.
C       (NOTE THAT LOGIC RELIES ON ASF POINTERS BEING
C       A CONTIGUOUS SEQUENCE!!)
C
        DO 439 I=IAFAIS,IAFACI
           AGPEND(4) = AGPEND(4) .OR. ASFCHG(I)
439     CONTINUE
C
C
        RETURN
C
        END
