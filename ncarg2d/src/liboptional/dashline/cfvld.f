C
C	$Id: cfvld.f,v 1.4 2006-03-16 17:32:33 kennison Exp $
C                                                                      
C                Copyright (C)  2000
C        University Corporation for Atmospheric Research
C                All Rights Reserved
C
C This file is free software; you can redistribute it and/or modify
C it under the terms of the GNU General Public License as published
C by the Free Software Foundation; either version 2 of the License, or
C (at your option) any later version.
C
C This software is distributed in the hope that it will be useful, but
C WITHOUT ANY WARRANTY; without even the implied warranty of
C MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
C General Public License for more details.
C
C You should have received a copy of the GNU General Public License
C along with this software; if not, write to the Free Software
C Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
C USA.
C
      SUBROUTINE CFVLD (IENTRY,IIX,IIY)
C
C CFVLD CONNECTS POINTS WHOSE COORDINATES ARE SUPPLIED IN THE ARGUMENTS,
C ACCORDING TO THE DASH PATTERN WHICH IS PASSED FROM ROUTINE DASHDB IN
C THE ARRAY IP IN COMMON DSHD.
C
C
      COMMON /DSHD/   ISL        ,L          ,IP(16)
      COMMON /DSHDA/  IFSTFL
      COMMON /DSHDB/ X,Y,X2,Y2,M,BTI,IB,IX,IY
      COMMON/INTPR/IPAU,FPART,TENSN,NP,SMALL,L1,ADDLR,ADDTB,MLLINE,
     1    ICLOSE
      SAVE
C
C CMN IS USED TO DETERMINE WHEN TO STOP DRAWING A LINE SEGMENT
C
      DATA CMN/1.5/
C
C IMPOS IS USED AS AN IMPOSSIBLE PEN POSITION.
C
      DATA IMPOS /-9999/
C
C
C  ISL= -1  ALL BLANK  ) FLAG TO AVOID MOST CALCULATIONS
C        0  DASHED     )   IF PATTERN IS ALL SOLID OR
C        1  ALL SOLID  )   ALL BLANK
C
C     X,IX,Y,IY    CURRENT POSITION
C     X1,Y1        START OF A USER LINE SEGMENT
C     X2,Y2        END OF A USER LINE SEGMENT
C
C  SEGMENT TYPES ARE RECOGNIZED AS FOLLOWS
C     SOLID - WORD IN IP-ARRAY CONTAINS POSITIVE INTEGER LESS THAN
C              16*IPAU*2**(15-10)
C     GAP - WORD IN IP-ARRAY CONTAINS NEGATIVE INTEGER, ABSOLUTE VALUE
C              OF WHICH IS LESS THAN 16*IPAU*2**(15-10)
C     THE IP ARRAY IS COMPOSED OF L ELEMENTS.
C
C     BTI - BITS THIS INCREMENT
C     BPBX,BPBY BITS PER BIT X(Y)
C
C
C BRANCH DEPENDING ON FUNCTION TO BE PERFORMED.
C
      GO TO (330,305,350),IENTRY
C
C INITIALIZE VARIABLES (ENTRY FRSTD ONLY)
C
   30 CONTINUE
      X = IX
      Y = IY
      X2 = X
      Y2 = Y
      M = 1
      MX = ABS(IP(1))
      BTI = MX
      IB = SIGN(1,IP(1))
      GO TO 300
C
C MAIN LOOP START
C
   50 CONTINUE
         X1 = X2
         Y1 = Y2
         MX = IIX
         MY = IIY
         X2 = MX
         Y2 = MY
         DX = X2-X1
         DY = Y2-Y1
         D = SQRT(DX*DX+DY*DY)
         IF (D .LT. CMN) GO TO 190
         BPBX = DX/D
         BPBY = DY/D
         CALL DRAWPV (IX,IY,0)
   70    BTI = BTI-D
         IF (BTI) 100,100,80
C
C LINE SEGMENT WILL FIT IN CURRENT PATTERN ELEMENT
C
   80    X = X2
         Y = Y2
         IX = X2
         IY = Y2
         IF (IB) 200,300,90
   90    CALL DRAWPV (IX,IY,1)
         GO TO 200
C
C LINE SEGMENT WONT FIT IN CURRENT PATTERN ELEMENT
C DO IT TO END OF ELEMENT, SAVE HOW MUCH OF SEGMENT LEFT TO DO (D)
C
  100    BTI = BTI+D
         D = D-BTI
         X = X+BPBX*BTI
         Y = Y+BPBY*BTI
         IX = X+.5
         IY = Y+.5
         IF (IB) 110,300,120
  110    CALL DRAWPV (IX,IY,0)
         GO TO 130
  120    CALL DRAWPV (IX,IY,1)
C
C GET THE NEXT PATTERN ELEMENT
C
  130    M = MOD(M,L)+1
         MX = ABS(IP(M))
         BTI = MX
         IB = SIGN(1,IP(M))
         GO TO 70
  190    X2 = X1
         Y2 = Y1
  200 CONTINUE
  300 RETURN
C
C *************************************
C
C ENTRY VECTD (XX,YY)
C
  305 CONTINUE
C
C TEST FOR PREVIOUS CALL TO FRSTD.
C
      IF (IFSTFL .EQ. 2) GO TO 310
C
C INFORM USER - NO PREVIOUS CALL TO FRSTD. TREAT CALL AS FRSTD CALL.
C
      CALL SETER('CFVLD - VECTD CALL OCCURS BEFORE A CALL TO FRSTD',
     -           2,2)
      GO TO 330
  310 CONTINUE
      IF (ISL) 300,50,320
  320 IX = IIX
      IY = IIY
      CALL DRAWPV (IX,IY,1)
      GO TO 300
C
C *************************************
C
C     ENTRY FRSTD (FLDX,FLDY)
C
  330 IX = IIX
      IY = IIY
      IFSTFL = 2
C AVOID UNEXPECTED PEN POSITION IF CALLS TO SYSTEM PLOT PACKAGE
C ROUTINES WERE MADE.
      CALL DRAWPV (IMPOS,IMPOS,2)
      IF (ISL) 300,30,340
  340 CALL DRAWPV (IX,IY,0)
      GO TO 300
C
C *************************************
C
C     ENTRY LASTD
C
  350 CONTINUE
C
C     THIS ENTRY JUST FOR UPWARD COMPATIBILITY
C
      GO TO 300
      END
