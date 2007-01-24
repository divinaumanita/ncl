C
C $Id: mdlacd.f,v 1.1 2007-01-24 23:42:39 kennison Exp $
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
      SUBROUTINE MDLACD (RLAT,CHRS,NCHR,NOFD)
C
C This routine, given a latitude RLAT and a character buffer CHRS,
C returns CHRS and NCHR such that CHRS(1:NCHR), when written by PLCHHQ,
C will yield a representation of RLAT in degrees and possibly fractions
C of a degree north or south of the equator.
C
        DOUBLE PRECISION RLAT
        CHARACTER*(*)    CHRS
        INTEGER          NCHR,NOFD
C
C Declare local variables.
C
        INTEGER          I,ILAT
C
C Compute the absolute value of the latitude in units of 10**(-5)
C degrees, limiting it to the range [0,9000000].
C
        ILAT=MIN(9000000,INT(100000.D0*ABS(RLAT)+.5D0))
C
C If the value is zero, return a string that will make PLCHHQ write a
C 0 followed by a degree sign.
C
        IF (ILAT.EQ.0) THEN
          NCHR=7
          CHRS='0:F34:0'
          RETURN
        END IF
C
C Otherwise, put blanks in the buffer and zero the current character
C count.
C
        CHRS=' '
        NCHR=0
C
C Put the number of degrees in the buffer.
C
        CALL MDINCH (ILAT/100000,CHRS,NCHR)
C
C If there is to be a fractional part, put it in the buffer.
C
        IF (NOFD.NE.0) THEN
          NCHR=NCHR+1
          CHRS(NCHR:NCHR)='.'
          DO 101 I=1,NOFD
            CALL MDINCH (MOD(ILAT/10**(5-I),10),CHRS,NCHR)
  101     CONTINUE
        END IF
C
C Add the code for a degree sign to the buffer.
C
        NCHR=NCHR+9
        CHRS(NCHR-8:NCHR)=':F34:0:F:'
C
C Finally, put either an "S" or an "N" in the buffer.
C
        NCHR=NCHR+1
C
        IF (RLAT.LT.0.) THEN
          CHRS(NCHR:NCHR)='S'
        ELSE
          CHRS(NCHR:NCHR)='N'
        END IF
C
C Done.
C
        RETURN
C
      END
