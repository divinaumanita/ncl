C
C	$Id: ezhftn.f,v 1.1.1.1 1992-04-17 22:31:22 ncargd Exp $
C
      SUBROUTINE EZHFTN (Z,M,N)
C
      DIMENSION       Z(M,N)
      SAVE
C
C HALF-TONE PICTURE VIA SHORTEST ARGUMENT LIST.
C ASSUMPTIONS--
C     ALL OF THE ARRAY IS TO BE DRAWN,
C     LOWEST VALUE IN Z WILL BE AT LOWEST INTENSITY ON READER/PRINTER
C     OUTPUT, HIGHEST VALUE IN Z WILL BE AT HIGHEST INTENSITY, VALUES IN
C     BETWEEN WILL APPEAR LINEARLY SPACED, MAXIMUM POSSIBLE NUMBER OF
C     INTENSITIES ARE USED, THE PICTURE WILL HAVE A PERIMETER DRAWN,
C     FRAME WILL BE CALLED AFTER THE PICTURE IS DRAWN, Z IS FILLED WITH
C     NUMBERS THAT SHOULD BE USED (NO UNKNOWN VALUES).
C IF THESE CONDITIONS ARE NOT MET, USE HAFTON.
C EZHFTN ARGUMENTS--
C     Z   2 DIMENSIONAL ARRAY TO BE USED TO GENERATE A HALF-TONE PLOT.
C     M   FIRST DIMENSION OF Z.
C     N   SECOND DIMENSION OF Z.
C
      DATA FLO,HI,NLEV,NOPT,NPRM,ISPV,SPV/0.0,0.0,0,0,0,0,0.0/
C
C THE FOLLOWING CALL IS FOR GATHERING STATISTICS ON LIBRARY USE AT NCAR
C
      CALL Q8QST4 ('GRAPHX','HAFTON','EZHFTN','VERSION  1')
C
      CALL HAFTON (Z,M,M,N,FLO,HI,NLEV,NOPT,NPRM,ISPV,SPV)
      CALL FRAME
      RETURN
      END
