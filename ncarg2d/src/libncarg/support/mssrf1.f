C
C	$Id: mssrf1.f,v 1.1.1.1 1992-04-17 22:32:38 ncargd Exp $
C
      SUBROUTINE MSSRF1 (M,N,X,Y,Z,IZ,ZX1,ZXM,ZY1,ZYN,ZXY11,
     *                  ZXYM1,ZXY1N,ZXYMN,ISLPSW,ZP,TEMP,
     *                  SIGMA,IERR)
C
      INTEGER M,N,IZ,ISLPSW,IERR
      REAL X(M),Y(N),Z(IZ,N),ZX1(N),ZXM(N),ZY1(M),ZYN(M),
     *     ZXY11,ZXYM1,ZXY1N,ZXYMN,ZP(M,N,3),TEMP(1),SIGMA
C
C ---------------------------------------------------------------------
C Note:  This routine comes from a proprietary package called FITPACK.
C It is used in the NCAR graphics package by permission of the author,
C Alan Cline.
C ---------------------------------------------------------------------
C
C                                            CODED BY ALAN KAYLOR CLINE
C                                         FROM FITPACK -- JUNE 22, 1986
C                                   A CURVE AND SURFACE FITTING PACKAGE
C                                 A PRODUCT OF PLEASANT VALLEY SOFTWARE
C                             8603 ALTUS COVE, AUSTIN, TEXAS 78759, USA
C
C ---------------------------------------------------------------------
C
C THIS SUBROUTINE DETERMINES THE PARAMETERS NECESSARY TO
C COMPUTE AN INTERPOLATORY SURFACE PASSING THROUGH A RECT-
C ANGULAR GRID OF FUNCTIONAL VALUES. THE SURFACE DETERMINED
C CAN BE REPRESENTED AS THE TENSOR PRODUCT OF SPLINES UNDER
C TENSION. THE X- AND Y-PARTIAL DERIVATIVES AROUND THE
C BOUNDARY AND THE X-Y-PARTIAL DERIVATIVES AT THE FOUR
C CORNERS MAY BE SPECIFIED OR OMITTED. FOR ACTUAL MAPPING
C OF POINTS ONTO THE SURFACE IT IS NECESSARY TO CALL THE
C FUNCTION MSSRF2.
C
C ON INPUT--
C
C   M IS THE NUMBER OF GRID LINES IN THE X-DIRECTION, I. E.
C   LINES PARALLEL TO THE Y-AXIS (M .GE. 2).
C
C   N IS THE NUMBER OF GRID LINES IN THE Y-DIRECTION, I. E.
C   LINES PARALLEL TO THE X-AXIS (N .GE. 2).
C
C   X IS AN ARRAY OF THE M X-COORDINATES OF THE GRID LINES
C   IN THE X-DIRECTION. THESE SHOULD BE STRICTLY INCREASING.
C
C   Y IS AN ARRAY OF THE N Y-COORDINATES OF THE GRID LINES
C   IN THE Y-DIRECTION. THESE SHOULD BE STRICTLY INCREASING.
C
C   Z IS AN ARRAY OF THE M * N FUNCTIONAL VALUES AT THE GRID
C   POINTS, I. E. Z(I,J) CONTAINS THE FUNCTIONAL VALUE AT
C   (X(I),Y(J)) FOR I = 1,...,M AND J = 1,...,N.
C
C   IZ IS THE ROW DIMENSION OF THE MATRIX Z USED IN THE
C   CALLING PROGRAM (IZ .GE. M).
C
C   ZX1 AND ZXM ARE ARRAYS OF THE M X-PARTIAL DERIVATIVES
C   OF THE FUNCTION ALONG THE X(1) AND X(M) GRID LINES,
C   RESPECTIVELY. THUS ZX1(J) AND ZXM(J) CONTAIN THE X-PART-
C   IAL DERIVATIVES AT THE POINTS (X(1),Y(J)) AND
C   (X(M),Y(J)), RESPECTIVELY, FOR J = 1,...,N. EITHER OF
C   THESE PARAMETERS WILL BE IGNORED (AND APPROXIMATIONS
C   SUPPLIED INTERNALLY) IF ISLPSW SO INDICATES.
C
C   ZY1 AND ZYN ARE ARRAYS OF THE N Y-PARTIAL DERIVATIVES
C   OF THE FUNCTION ALONG THE Y(1) AND Y(N) GRID LINES,
C   RESPECTIVELY. THUS ZY1(I) AND ZYN(I) CONTAIN THE Y-PART-
C   IAL DERIVATIVES AT THE POINTS (X(I),Y(1)) AND
C   (X(I),Y(N)), RESPECTIVELY, FOR I = 1,...,M. EITHER OF
C   THESE PARAMETERS WILL BE IGNORED (AND ESTIMATIONS
C   SUPPLIED INTERNALLY) IF ISLPSW SO INDICATES.
C
C   ZXY11, ZXYM1, ZXY1N, AND ZXYMN ARE THE X-Y-PARTIAL
C   DERIVATIVES OF THE FUNCTION AT THE FOUR CORNERS,
C   (X(1),Y(1)), (X(M),Y(1)), (X(1),Y(N)), AND (X(M),Y(N)),
C   RESPECTIVELY. ANY OF THE PARAMETERS WILL BE IGNORED (AND
C   ESTIMATIONS SUPPLIED INTERNALLY) IF ISLPSW SO INDICATES.
C
C   ISLPSW CONTAINS A SWITCH INDICATING WHICH BOUNDARY
C   DERIVATIVE INFORMATION IS USER-SUPPLIED AND WHICH
C   SHOULD BE ESTIMATED BY THIS SUBROUTINE. TO DETERMINE
C   ISLPSW, LET
C        I1 = 0 IF ZX1 IS USER-SUPPLIED (AND = 1 OTHERWISE),
C        I2 = 0 IF ZXM IS USER-SUPPLIED (AND = 1 OTHERWISE),
C        I3 = 0 IF ZY1 IS USER-SUPPLIED (AND = 1 OTHERWISE),
C        I4 = 0 IF ZYN IS USER-SUPPLIED (AND = 1 OTHERWISE),
C        I5 = 0 IF ZXY11 IS USER-SUPPLIED
C                                       (AND = 1 OTHERWISE),
C        I6 = 0 IF ZXYM1 IS USER-SUPPLIED
C                                       (AND = 1 OTHERWISE),
C        I7 = 0 IF ZXY1N IS USER-SUPPLIED
C                                       (AND = 1 OTHERWISE),
C        I8 = 0 IF ZXYMN IS USER-SUPPLIED
C                                       (AND = 1 OTHERWISE),
C   THEN ISLPSW = I1 + 2*I2 + 4*I3 + 8*I4 + 16*I5 + 32*I6
C                   + 64*I7 + 128*I8
C   THUS ISLPSW = 0 INDICATES ALL DERIVATIVE INFORMATION IS
C   USER-SUPPLIED AND ISLPSW = 255 INDICATES NO DERIVATIVE
C   INFORMATION IS USER-SUPPLIED. ANY VALUE BETWEEN THESE
C   LIMITS IS VALID.
C
C   ZP IS AN ARRAY OF AT LEAST 3*M*N LOCATIONS.
C
C   TEMP IS AN ARRAY OF AT LEAST N+N+M LOCATIONS WHICH IS
C   USED FOR SCRATCH STORAGE.
C
C AND
C
C   SIGMA CONTAINS THE TENSION FACTOR. THIS VALUE INDICATES
C   THE CURVINESS DESIRED. IF ABS(SIGMA) IS NEARLY ZERO
C   (E. G. .001) THE RESULTING SURFACE IS APPROXIMATELY THE
C   TENSOR PRODUCT OF CUBIC SPLINES. IF ABS(SIGMA) IS LARGE
C   (E. G. 50.) THE RESULTING SURFACE IS APPROXIMATELY
C   BI-LINEAR. IF SIGMA EQUALS ZERO TENSOR PRODUCTS OF
C   CUBIC SPLINES RESULT. A STANDARD VALUE FOR SIGMA IS
C   APPROXIMATELY 1. IN ABSOLUTE VALUE.
C
C ON OUTPUT--
C
C   ZP CONTAINS THE VALUES OF THE XX-, YY-, AND XXYY-PARTIAL
C   DERIVATIVES OF THE SURFACE AT THE GIVEN NODES.
C
C   IERR CONTAINS AN ERROR FLAG,
C        = 0 FOR NORMAL RETURN,
C        = 1 IF N IS LESS THAN 2 OR M IS LESS THAN 2,
C        = 2 IF THE X-VALUES OR Y-VALUES ARE NOT STRICTLY
C            INCREASING.
C
C AND
C
C   M, N, X, Y, Z, IZ, ZX1, ZXM, ZY1, ZYN, ZXY11, ZXYM1,
C   ZXY1N, ZXYMN, ISLPSW, AND SIGMA ARE UNALTERED.
C
C THIS SUBROUTINE REFERENCES PACKAGE MODULES MSCEEZ, MSTRMS,
C AND MSSHCH.
C
C-----------------------------------------------------------
C
      MM1 = M-1
      MP1 = M+1
      NM1 = N-1
      NP1 = N+1
      NPM = N+M
      IERR = 0
      IF (N .LE. 1 .OR. M .LE. 1) GO TO 46
      IF (Y(N) .LE. Y(1)) GO TO 47
C
C DENORMALIZE TENSION FACTOR IN Y-DIRECTION
C
      SIGMAY = ABS(SIGMA)*FLOAT(N-1)/(Y(N)-Y(1))
C
C OBTAIN Y-PARTIAL DERIVATIVES ALONG Y = Y(1)
C
      IF ((ISLPSW/8)*2 .NE. (ISLPSW/4)) GO TO 2
      DO 1 I = 1,M
    1   ZP(I,1,1) = ZY1(I)
      GO TO 5
    2 DELY1 = Y(2)-Y(1)
      DELY2 = DELY1+DELY1
      IF (N .GT. 2) DELY2 = Y(3)-Y(1)
      IF (DELY1 .LE. 0. .OR. DELY2 .LE. DELY1) GO TO 47
      CALL MSCEEZ (DELY1,DELY2,SIGMAY,C1,C2,C3,N)
      DO 3 I = 1,M
    3   ZP(I,1,1) = C1*Z(I,1)+C2*Z(I,2)
      IF (N .EQ. 2) GO TO 5
      DO 4 I = 1,M
    4   ZP(I,1,1) = ZP(I,1,1)+C3*Z(I,3)
C
C OBTAIN Y-PARTIAL DERIVATIVES ALONG Y = Y(N)
C
    5 IF ((ISLPSW/16)*2 .NE. (ISLPSW/8)) GO TO 7
      DO 6 I = 1,M
        NPI = N+I
    6   TEMP(NPI) = ZYN(I)
      GO TO 10
    7 DELYN = Y(N)-Y(NM1)
      DELYNM = DELYN+DELYN
      IF (N .GT. 2) DELYNM = Y(N)-Y(N-2)
      IF (DELYN .LE. 0. .OR. DELYNM .LE. DELYN) GO TO 47
      CALL MSCEEZ (-DELYN,-DELYNM,SIGMAY,C1,C2,C3,N)
      DO 8 I = 1,M
        NPI = N+I
    8   TEMP(NPI) = C1*Z(I,N)+C2*Z(I,NM1)
      IF (N .EQ. 2) GO TO 10
      DO 9 I = 1,M
        NPI = N+I
    9   TEMP(NPI) = TEMP(NPI)+C3*Z(I,N-2)
   10 IF (X(M) .LE. X(1)) GO TO 47
C
C DENORMALIZE TENSION FACTOR IN X-DIRECTION
C
      SIGMAX = ABS(SIGMA)*FLOAT(M-1)/(X(M)-X(1))
C
C OBTAIN X-PARTIAL DERIVATIVES ALONG X = X(1)
C
      IF ((ISLPSW/2)*2 .NE. ISLPSW) GO TO 12
      DO 11 J = 1,N
   11   ZP(1,J,2) = ZX1(J)
      IF ((ISLPSW/32)*2 .EQ. (ISLPSW/16) .AND.
     *    (ISLPSW/128)*2  .EQ. (ISLPSW/64)) GO TO 15
   12 DELX1 = X(2)-X(1)
      DELX2 = DELX1+DELX1
      IF (M .GT. 2) DELX2 = X(3)-X(1)
      IF (DELX1 .LE. 0. .OR. DELX2 .LE. DELX1) GO TO 47
      CALL MSCEEZ (DELX1,DELX2,SIGMAX,C1,C2,C3,M)
      IF ((ISLPSW/2)*2 .EQ. ISLPSW) GO TO 15
      DO 13 J = 1,N
   13   ZP(1,J,2) = C1*Z(1,J)+C2*Z(2,J)
      IF (M .EQ. 2) GO TO 15
      DO 14 J = 1,N
   14   ZP(1,J,2) = ZP(1,J,2)+C3*Z(3,J)
C
C OBTAIN X-Y-PARTIAL DERIVATIVE AT (X(1),Y(1))
C
   15 IF ((ISLPSW/32)*2 .NE. (ISLPSW/16)) GO TO 16
      ZP(1,1,3) = ZXY11
      GO TO 17
   16 ZP(1,1,3) = C1*ZP(1,1,1)+C2*ZP(2,1,1)
      IF (M .GT. 2) ZP(1,1,3) = ZP(1,1,3)+C3*ZP(3,1,1)
C
C OBTAIN X-Y-PARTIAL DERIVATIVE AT (X(1),Y(N))
C
   17 IF ((ISLPSW/128)*2 .NE. (ISLPSW/64)) GO TO 18
      ZXY1NS = ZXY1N
      GO TO 19
   18 ZXY1NS = C1*TEMP(N+1)+C2*TEMP(N+2)
      IF (M .GT. 2) ZXY1NS = ZXY1NS+C3*TEMP(N+3)
C
C OBTAIN X-PARTIAL DERIVATIVE ALONG X = X(M)
C
   19 IF ((ISLPSW/4)*2 .NE. (ISLPSW/2)) GO TO 21
      DO 20 J = 1,N
        NPMPJ = NPM+J
   20   TEMP(NPMPJ) = ZXM(J)
      IF ((ISLPSW/64)*2 .EQ. (ISLPSW/32) .AND.
     *    (ISLPSW/256)*2 .EQ. (ISLPSW/128)) GO TO 24
   21 DELXM = X(M)-X(MM1)
      DELXMM = DELXM+DELXM
      IF (M .GT. 2) DELXMM = X(M)-X(M-2)
      IF (DELXM .LE. 0. .OR. DELXMM .LE. DELXM) GO TO 47
      CALL MSCEEZ (-DELXM,-DELXMM,SIGMAX,C1,C2,C3,M)
      IF ((ISLPSW/4)*2 .EQ. (ISLPSW/2)) GO TO 24
      DO 22 J = 1,N
        NPMPJ = NPM+J
   22   TEMP(NPMPJ) = C1*Z(M,J)+C2*Z(MM1,J)
      IF (M .EQ. 2) GO TO 24
      DO 23 J = 1,N
        NPMPJ = NPM+J
   23   TEMP(NPMPJ) = TEMP(NPMPJ)+C3*Z(M-2,J)
C
C OBTAIN X-Y-PARTIAL DERIVATIVE AT (X(M),Y(1))
C
   24 IF ((ISLPSW/64)*2 .NE. (ISLPSW/32)) GO TO 25
      ZP(M,1,3) = ZXYM1
      GO TO 26
   25 ZP(M,1,3) = C1*ZP(M,1,1)+C2*ZP(MM1,1,1)
      IF (M .GT. 2) ZP(M,1,3) = ZP(M,1,3)+C3*ZP(M-2,1,1)
C
C OBTAIN X-Y-PARTIAL DERIVATIVE AT (X(M),Y(N))
C
   26 IF ((ISLPSW/256)*2 .NE. (ISLPSW/128)) GO TO 27
      ZXYMNS = ZXYMN
      GO TO 28
   27 ZXYMNS = C1*TEMP(NPM)+C2*TEMP(NPM-1)
      IF (M .GT. 2) ZXYMNS = ZXYMNS+C3*TEMP(NPM-2)
C
C SET UP RIGHT HAND SIDES AND TRIDIAGONAL SYSTEM FOR Y-GRID
C PERFORM FORWARD ELIMINATION
C
   28 DEL1 = Y(2)-Y(1)
      IF (DEL1 .LE. 0.) GO TO 47
      DELI = 1./DEL1
      DO 29 I = 1,M
   29   ZP(I,2,1) = DELI*(Z(I,2)-Z(I,1))
      ZP(1,2,3) = DELI*(ZP(1,2,2)-ZP(1,1,2))
      ZP(M,2,3) = DELI*(TEMP(NPM+2)-TEMP(NPM+1))
      CALL MSTRMS (DIAG1,SDIAG1,SIGMAY,DEL1)
      DIAGI = 1./DIAG1
      DO 30 I = 1,M
   30   ZP(I,1,1) = DIAGI*(ZP(I,2,1)-ZP(I,1,1))
      ZP(1,1,3) = DIAGI*(ZP(1,2,3)-ZP(1,1,3))
      ZP(M,1,3) = DIAGI*(ZP(M,2,3)-ZP(M,1,3))
      TEMP(1) = DIAGI*SDIAG1
      IF (N .EQ. 2) GO TO 34
      DO 33 J = 2,NM1
        JM1 = J-1
        JP1 = J+1
        NPMPJ = NPM+J
        DEL2 = Y(JP1)-Y(J)
        IF (DEL2 .LE. 0.) GO TO 47
        DELI = 1./DEL2
        DO 31 I = 1,M
   31     ZP(I,JP1,1) = DELI*(Z(I,JP1)-Z(I,J))
        ZP(1,JP1,3) = DELI*(ZP(1,JP1,2)-ZP(1,J,2))
        ZP(M,JP1,3) = DELI*(TEMP(NPMPJ+1)-TEMP(NPMPJ))
        CALL MSTRMS (DIAG2,SDIAG2,SIGMAY,DEL2)
        DIAGIN = 1./(DIAG1+DIAG2-SDIAG1*TEMP(JM1))
        DO 32 I = 1,M
   32     ZP(I,J,1) = DIAGIN*(ZP(I,JP1,1)-ZP(I,J,1)-
     *                        SDIAG1*ZP(I,JM1,1))
        ZP(1,J,3) = DIAGIN*(ZP(1,JP1,3)-ZP(1,J,3)-
     *                      SDIAG1*ZP(1,JM1,3))
        ZP(M,J,3) = DIAGIN*(ZP(M,JP1,3)-ZP(M,J,3)-
     *                      SDIAG1*ZP(M,JM1,3))
        TEMP(J) = DIAGIN*SDIAG2
        DIAG1 = DIAG2
   33   SDIAG1 = SDIAG2
   34 DIAGIN = 1./(DIAG1-SDIAG1*TEMP(NM1))
      DO 35 I = 1,M
        NPI = N+I
   35   ZP(I,N,1) = DIAGIN*(TEMP(NPI)-ZP(I,N,1)-
     *                      SDIAG1*ZP(I,NM1,1))
      ZP(1,N,3) = DIAGIN*(ZXY1NS-ZP(1,N,3)-
     *                    SDIAG1*ZP(1,NM1,3))
      TEMP(N) = DIAGIN*(ZXYMNS-ZP(M,N,3)-
     *                  SDIAG1*ZP(M,NM1,3))
C
C PERFORM BACK SUBSTITUTION
C
      DO 37 J = 2,N
        JBAK = NP1-J
        JBAKP1 = JBAK+1
        T = TEMP(JBAK)
        DO 36 I = 1,M
   36     ZP(I,JBAK,1) = ZP(I,JBAK,1)-T*ZP(I,JBAKP1,1)
        ZP(1,JBAK,3) = ZP(1,JBAK,3)-T*ZP(1,JBAKP1,3)
   37   TEMP(JBAK) = ZP(M,JBAK,3)-T*TEMP(JBAKP1)
C
C SET UP RIGHT HAND SIDES AND TRIDIAGONAL SYSTEM FOR X-GRID
C PERFORM FORWARD ELIMINATION
C
      DEL1 = X(2)-X(1)
      IF (DEL1 .LE. 0.) GO TO 47
      DELI = 1./DEL1
      DO 38 J = 1,N
        ZP(2,J,2) = DELI*(Z(2,J)-Z(1,J))
   38   ZP(2,J,3) = DELI*(ZP(2,J,1)-ZP(1,J,1))
      CALL MSTRMS (DIAG1,SDIAG1,SIGMAX,DEL1)
      DIAGI = 1./DIAG1
      DO 39 J = 1,N
        ZP(1,J,2) = DIAGI*(ZP(2,J,2)-ZP(1,J,2))
   39   ZP(1,J,3) = DIAGI*(ZP(2,J,3)-ZP(1,J,3))
      TEMP(N+1) = DIAGI*SDIAG1
      IF (M  .EQ. 2) GO TO 43
      DO 42 I = 2,MM1
        IM1 = I-1
        IP1 = I+1
        NPI = N+I
        DEL2 = X(IP1)-X(I)
        IF (DEL2 .LE. 0.) GO TO 47
        DELI = 1./DEL2
        DO 40 J = 1,N
          ZP(IP1,J,2) = DELI*(Z(IP1,J)-Z(I,J))
   40     ZP(IP1,J,3) = DELI*(ZP(IP1,J,1)-ZP(I,J,1))
        CALL MSTRMS (DIAG2,SDIAG2,SIGMAX,DEL2)
        DIAGIN = 1./(DIAG1+DIAG2-SDIAG1*TEMP(NPI-1))
        DO 41 J = 1,N
          ZP(I,J,2) = DIAGIN*(ZP(IP1,J,2)-ZP(I,J,2)-
     *                        SDIAG1*ZP(IM1,J,2))
   41     ZP(I,J,3) = DIAGIN*(ZP(IP1,J,3)-ZP(I,J,3)-
     *                        SDIAG1*ZP(IM1,J,3))
        TEMP(NPI) = DIAGIN*SDIAG2
        DIAG1 = DIAG2
   42   SDIAG1 = SDIAG2
   43 DIAGIN = 1./(DIAG1-SDIAG1*TEMP(NPM-1))
      DO 44 J = 1,N
        NPMPJ = NPM+J
        ZP(M,J,2) = DIAGIN*(TEMP(NPMPJ)-ZP(M,J,2)-
     *                      SDIAG1*ZP(MM1,J,2))
   44   ZP(M,J,3) = DIAGIN*(TEMP(J)-ZP(M,J,3)-
     *                      SDIAG1*ZP(MM1,J,3))
C
C PERFORM BACK SUBSTITUTION
C
      DO 45 I = 2,M
        IBAK = MP1-I
        IBAKP1 = IBAK+1
        NPIBAK = N+IBAK
        T = TEMP(NPIBAK)
        DO 45 J = 1,N
          ZP(IBAK,J,2) = ZP(IBAK,J,2)-T*ZP(IBAKP1,J,2)
   45     ZP(IBAK,J,3) = ZP(IBAK,J,3)-T*ZP(IBAKP1,J,3)
      RETURN
C
C TOO FEW POINTS
C
   46 IERR = 1
      RETURN
C
C POINTS NOT STRICTLY INCREASING
C
   47 IERR = 2
      RETURN
      END
