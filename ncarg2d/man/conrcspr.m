.\"
.\"	$Id: conrcspr.m,v 1.1.1.1 1992-04-17 22:30:20 ncargd Exp $
.\"
.TH CONRCSPR 3NCARG "MARCH 1988" NCAR "NCAR GRAPHICS"
.so MACRO_SOURCE
.dsNA " CONRECSPR - Contours 2-d arrays, lines smoothed, crowded lines removed
.dsS1 " CALL EZCNTR (Z,M,N) if criteria below is met, else
.nrsN 1
./" USE tsi to PRINT THIS FILE!
.pn 171
.bp
.PH ""
.PF ""
.SK 1
.tr ~
.po -.25i
.ll 6.5i
.PH ""
.EH "@\s9NCAR Graphics User's Guide\s11@@@"
.OH "@@@\s9CONRECSPR\s11@"
.EF "@\s\fB11%\s9\fR@@August 1987\s11@"
.OF "@\s9August 1987@@\s11\fB%\fR@"
.de hD          \" Heading macro level one
.br
.ne 5
.sp 2
.ps +3
.ft B           \" boldface, 14 pt.
\\$1
.ft R
.ps -3
.sp 
..
.de >>          \" display for indented lines
.in +.25i       \" usage: .>>
.sp
.nf
..              
.de <<          \" end of display for indented lines
.fi
.in -.25i       \" usage: .<<
.sp
..              
.de sf          \"start fortran (constant spacing)
.ps 10
.vs 12
.nf
.ft L
..
.de ef          \"end fortran (resume variable spacing & prev. size & font)
.ft
.fi
.ps
.vs
..
.br
.S 14
.S 11
SUBROUTINE CONREC (Z,L,M,N,FLO,HI,FINC,NSET,NHI,NDOT)
.R
.H 3 "Dimension of Arguments"
Z(L,N)
.H 3 "Latest Revision"
August 1987
.H 3 "Purpose"
CONRECSPR draws a contour map from data
stored in a rectangular array, labeling
the lines.  This is the so-called "super"
version, which smooths contour lines and
removes crowded lines.
.H 3 "Usage"
If the following assumptions are met, use
.sp
CALL EZCNTR (Z,M,N)
.sp
ASSUMPTIONS:
.BL
.LI
All of the array is to be contoured.
.LI
Contour levels are picked
internally.
.LI
Contouring routine picks scale
factors.
.LI
Highs and lows are marked.
.LI
Negative lines are drawn with a
dashed line pattern.
.LI
EZCNTR calls FRAME after drawing the
contour map.
.LE
.sp
If these assumptions are not met, use
.sp
.nf
CALL CONREC (Z,L,M,N,FLO,HI,FINC,NSET,NHI,NDOT)
.fi
.H 3 "ARGUMENTS"
.H 3 "On Input for EZCNTR"
.VL .6i
.LI "\fBZ\fR"
M by N array to be contoured.
.LI "\fBM\fR"
First dimension of Z.
.LI "\fBN\fR"
Second dimension of Z.
.LE
.br
.H 3 "On Output for EZCNTR"
All arguments are unchanged.
.H 3 "On Input for CONREC"
.VL .6i
.LI "\fBZ\fR"
The (origin of the) array to be
contoured.  Z is dimensioned L by N.
.LI "\fBL\fR"
The first dimension of Z in the calling
program.
.LI "\fBM\fR"
The number of data values to be contoured
in the X-direction (the first subscript
direction).  When plotting an entire
array, L = M.
.LI "\fBN\fR"
The number of data values to be contoured
in the Y-direction (the second subscript
direction).
.LI "\fBFLO\fR"
The value of the lowest contour level.
If FLO = HI = 0., a value rounded up from
the minimum Z is generated by CONREC.
.LI "\fBHI\fR"
The value of the highest contour level.
If HI = FLO = 0., a value rounded down
from the maximum Z is generated by
.hw CONREC
CONREC.
.LI "\fBFINC\fR"
.VL 1c
.LI ">~0"
Increment between contour levels.
.LI "=~0"
A value, which produces between 10
and 30 contour levels at nice values,
is generated by CONREC.
.LI "<~0"
The number of levels generated by
CONREC is ABS(FINC).
.LE
.sp
.LI "\fBNSET\fR"
Flag to control scaling.
.VL 1c
.LI "=~0"
CONREC automatically sets the
window and viewport to properly
scale the frame to the standard
configuration.
The GRIDAL entry PERIM is
called and tick marks are placed
corresponding to the data points.
.LI ">~0"
CONREC assumes that the user
has set the window and viewport
in such a way as to properly
scale the plotting
instructions generated by CONREC.
PERIM is not called.
.LI "<~0"
CONREC generates coordinates so as
to place the (untransformed) contour
plot within the limits of the
user's current window and
viewport.  PERIM is not called.
.LE
.sp
.LI "\fBNHI\fR"
Flag to control extra information on the
contour plot.
.VL 1c
.LI "=~0"
Highs and lows are marked with an H
or L as appropriate, and the value
of the high or low is plotted under
the symbol.
.LI ">~0"
The data values are plotted at
each Z point, with the center of
the string indicating the data
point location.
.LI "<~0"
Neither of the above.
.LE
.sp
.LI "\fBNDOT\fR"
A 10-bit constant designating the desired
dashed line pattern.
If ABS(NDOT) = 0, 1, or 1023, solid lines
are drawn.
.VL 1c
.LI ">~0"
NDOT pattern is used for all lines.
.LI "<~0"
ABS(NDOT) pattern is used for negative-valued 
contour lines, and solid is
used for positive-valued contours.
CONREC converts NDOT
to a 16-bit pattern and DASHDB is used.
See DASHDB comments in the DASHLINE
documentation for details.
.LE
.H 3 "On Output for CONREC"
All arguments are unchanged.
.H 3 "Entry Points"
CONREC, CLGEN, REORD, STLINE, DRLINE,
MINMAX, PNTVAL, CALCNT, EZCNTR, CONBD
.H 3 "Common Blocks"
INTPR, SPRINT, CONRE1, CONRE2, CONRE3, CONRE4, CONRE5
.H 3 "Required Library Routines"
GRIDAL, the ERPRT77 package, and the SPPS.
DASHSUPR is also needed.
.H 3 "Required GKS Level"
0A
.H 3 "Note for NCAR Users"
This routine is NOT part of the default
.hw CONRECSPR
libraries at NCAR.  CONRECSPR must
be acquired, compiled, and loaded to be
used at NCAR.
.H 3 "I/O"
Plots contour map.
.H 3 "Precision"
Single
.H 3 "Language"
FORTRAN 77
.H 3 "History"
.H 3 "Algorithm"
Each line is followed to completion.  Points
along a line are found on boundaries of the
(rectangular) cells. These points are
connected by line segments using the
.hw DASHSUPR
software dashed line package, DASHSUPR.
DASHSUPR is also used to label the
lines.  In this version, a model of
the plotting plane is maintained.  If a
line to be drawn will overlap previously
drawn lines, it is omitted.
.H 3 "Note"
To draw non-uniform contour levels, see
the comments in CLGEN.  To make special
modifications for specific needs, see the
explanation of the internal parameters
below.
.H 3 "Timing"
Varies widely with size and smoothness of
Z.
.H 3 "Internal Parameters"
.TS
.if \n+(b.=1 .nr d. \n(.c-\n(c.-1
.de 35
.ps \n(.s
.vs \n(.vu
.in \n(.iu
.if \n(.u .fi
.if \n(.j .ad
.if \n(.j=0 .na
..
.nf
.nr #~ 0
.if n .nr #~ 0.6n
.ds #d .d
.if \(ts\n(.z\(ts\(ts .ds #d nl
.fc
.nr 33 \n(.s
.rm 80 81 82 83 84
.nr 34 \n(.lu
.eo
.am 82
.br
.di a+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Size of line labels,
as per the size definitions
given in the SPPS
documentation for WTSTR.
.br
.di
.nr a| \n(dn
.nr a- \n(dl
..
.ec \
.eo
.am 82
.br
.di b+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Size of labels for minimums
and maximums as per the
size definitions given in
the SPPS documentation for
WTSTR.
.br
.di
.nr b| \n(dn
.nr b- \n(dl
..
.ec \
.eo
.am 82
.br
.di c+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Size of labels for data
point values as per the size
definitions given in the SPPS
documentation for WTSTR.
.br
.di
.nr c| \n(dn
.nr c- \n(dl
..
.ec \
.eo
.am 82
.br
.di d+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Approximate number of
contour levels when
internally generated.
.br
.di
.nr d| \n(dn
.nr d- \n(dl
..
.ec \
.eo
.am 82
.br
.di e+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Maximum number of contour
levels.  If this is to be
increased, the dimensions
of CL and RWORK in CONREC
must be increased by the
same amount.
.br
.di
.nr e| \n(dn
.nr e- \n(dl
..
.ec \
.eo
.am 82
.br
.di f+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Left hand edge of the plot
(0.0 is the left edge of
the frame and 1.0 is the
right edge of the frame.)
.br
.di
.nr f| \n(dn
.nr f- \n(dl
..
.ec \
.eo
.am 82
.br
.di g+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Bottom edge of the plot
(0.0 is the bottom of the
frame and 1.0 is the top
of the frame.)
.br
.di
.nr g| \n(dn
.nr g- \n(dl
..
.ec \
.eo
.am 82
.br
.di h+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Length of longer edge of
plot (see also EXT).
.br
.di
.nr h| \n(dn
.nr h- \n(dl
..
.ec \
.eo
.am 82
.br
.di i+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Number of repetitions of
the dash pattern between
line labels.
.br
.di
.nr i| \n(dn
.nr i- \n(dl
..
.ec \
.eo
.am 82
.br
.di j+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Number of CRT units per
element (bit) in the dash
pattern.
.br
.di
.nr j| \n(dn
.nr j- \n(dl
..
.ec \
.eo
.am 82
.br
.di k+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Flag to control the drawing
of line labels.
.sp
.BL
.LI
ILAB non-zero means label
the lines.
.LI
ILAB = 0 means do not
label the lines.
.LE
.br
.di
.nr k| \n(dn
.nr k- \n(dl
..
.ec \
.eo
.am 82
.br
.di l+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Number of unlabeled lines
between labeled lines.  For
example, when NULBLL = 3,
every fourth level is
labeled.
.br
.di
.nr l| \n(dn
.nr l- \n(dl
..
.ec \
.eo
.am 82
.br
.di m+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Flag to control
normalization of label
numbers.
.sp
.BL
.LI
IOFFD = 0 means include
decimal point when
possible (do not
normalize unless
required).
.LI
IOFFD non-zero means
normalize all label
numbers and output a
scale factor in the
message below the graph.
.LE
.br
.di
.nr m| \n(dn
.nr m- \n(dl
..
.ec \
.eo
.am 82
.br
.di n+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Lengths of the sides of the
plot are proportional to M
and N (when CONREC sets
the window and viewport).
In extreme cases, when
MIN(M,N)/MAX(M,N) is less
.hw CONREC
than EXT, CONREC
produces a square plot.
.br
.di
.nr n| \n(dn
.nr n- \n(dl
..
.ec \
.eo
.am 82
.br
.di o+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Flag to control special
value feature.
.sp
.BL
.LI
IOFFP = 0 means special
value feature not in use.
.LI
IOFFP non-zero means
special value feature in
use.  (SPVAL is set to the
special value.)  Contour
lines will then be
omitted from any cell
with any corner equal to
the special value.
.LE
.br
.di
.nr o| \n(dn
.nr o- \n(dl
..
.ec \
.eo
.am 82
.br
.di p+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Contains the special value
when IOFFP is non-zero.
.br
.di
.nr p| \n(dn
.nr p- \n(dl
..
.ec \
.eo
.am 82
.br
.di q+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Flag to control the message
below the plot.
.sp
.BL
.LI
IOFFM = 0  if the message
is to be plotted.
.LI
IOFFM non-zero if the
message is to be omitted.
.LE
.br
.di
.nr q| \n(dn
.nr q- \n(dl
..
.ec \
.eo
.am 82
.br
.di r+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Dash pattern for
non-negative contour lines.
.br
.di
.nr r| \n(dn
.nr r- \n(dl
..
.ec \
.eo
.am 82
.br
.di s+
.35
.ft \n(.f
.ll \n(34u*3u/6u
.if \n(.l<\n(82 .ll \n(82u
.in 0
Flag to control labeling
of highs, lows, or both:
if NHI = 0 , then
.sp
.BL
.LI
IHILO = 0 means do not
label highs nor lows
.LI
IHILO = 1 means highs are
labeled, lows are not
.LI
IHILO = 2 means lows are
labeled, highs are not
.LI
IHILO = 3 means both
highs and lows are labeled
.LE
.br
.di
.nr s| \n(dn
.nr s- \n(dl
..
.ec \
.35
.nf
.ll \n(34u
.nr 80 0
.nr 38 \wName
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wISIZEL
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wISIZEM
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wName
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wISIZEP
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wNLA
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wNLM
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wXLT
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wYBT
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wSIDE
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wNREP
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wNCRT
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wILAB
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wNULBLL
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wIOFFD
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wName
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wEXT
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wIOFFP
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wSPVAL
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wIOFFM
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wISOLID
.if \n(80<\n(38 .nr 80 \n(38
.nr 38 \wIHILO
.if \n(80<\n(38 .nr 80 \n(38
.80
.rm 80
.nr 81 0
.nr 38 \wDefault
.if \n(81<\n(38 .nr 81 \n(38
.nr 31 0
.nr 32 0
.nr 38 \w1
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \w2
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \wDefault
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w0
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w16
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w40
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w.05
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w.05
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w0.9
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w6
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w4
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w1
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w3
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w0
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \wDefault
.if \n(81<\n(38 .nr 81 \n(38
.nr 38 \w.25
.if \n(32<\n(38 .nr 32 \n(38
.nr 38 \w0
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \w0
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \w.
.if \n(32<\n(38 .nr 32 \n(38
.nr 38 \w0
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \w1023
.if \n(31<\n(38 .nr 31 \n(38
.nr 38 \w3
.if \n(31<\n(38 .nr 31 \n(38
.81
.rm 81
.nr 61 \n(31
.nr 38 \n(61+\n(32
.if \n(38>\n(81 .nr 81 \n(38
.if \n(38<\n(81 .nr 61 +(\n(81-\n(38)/2
.nr 82 0
.82
.rm 82
.nr 83 0
.83
.rm 83
.nr 84 0
.84
.rm 84
.nr 38 \wFunction-\n(82-3n-\n(83-3n-\n(84
.if \n(38>0 .nr 38 \n(38/2
.if \n(38<0 .nr 38 0
.nr 82 +\n(38
.nr 83 +\n(38
.nr 38 \wFunction-\n(82-3n-\n(83-3n-\n(84
.if \n(38>0 .nr 38 \n(38/2
.if \n(38<0 .nr 38 0
.nr 82 +\n(38
.nr 83 +\n(38
.nr 38 \wFunction-\n(82-3n-\n(83-3n-\n(84
.if \n(38>0 .nr 38 \n(38/2
.if \n(38<0 .nr 38 0
.nr 82 +\n(38
.nr 83 +\n(38
.35
.nf
.ll \n(34u
.nr 38 1n
.nr 79 0
.nr 40 \n(79+(0*\n(38)
.nr 80 +\n(40
.nr 41 \n(80+(3*\n(38)
.nr 81 +\n(41
.nr 61 +\n(41
.nr 42 \n(81+(3*\n(38)
.nr 82 +\n(42
.nr 43 \n(82+(3*\n(38)
.nr 83 +\n(43
.nr 44 \n(83+(3*\n(38)
.nr 84 +\n(44
.nr TW \n(84
.fc  
.nr #T 0-1
.nr #a 0-1
.eo
.de T#
.ds #d .d
.if \(ts\n(.z\(ts\(ts .ds #d nl
.mk ##
.nr ## -1v
.ls 1
.ls
..
.ec
.B
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'Name\h'|\n(41u'Default\h'|\n(42u'Function
.R
.sp
.ne \n(a|u+\n(.Vu
.if (\n(a|+\n(#^-1v)>\n(#- .nr #- +(\n(a|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'ISIZEL\h'|\n(41u'1\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.a+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(b|u+\n(.Vu
.if (\n(b|+\n(#^-1v)>\n(#- .nr #- +(\n(b|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'ISIZEM\h'|\n(41u'2\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.b+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.bp
.T&
.B
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'Name\h'|\n(41u'Default\h'|\n(42u'Function
.R
.sp
.ne \n(c|u+\n(.Vu
.if (\n(c|+\n(#^-1v)>\n(#- .nr #- +(\n(c|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'ISIZEP\h'|\n(41u'0\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.c+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(d|u+\n(.Vu
.if (\n(d|+\n(#^-1v)>\n(#- .nr #- +(\n(d|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'NLA\h'|\n(41u'16\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.d+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(e|u+\n(.Vu
.if (\n(e|+\n(#^-1v)>\n(#- .nr #- +(\n(e|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'NLM\h'|\n(41u'40\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.e+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(f|u+\n(.Vu
.if (\n(f|+\n(#^-1v)>\n(#- .nr #- +(\n(f|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'XLT\h'|\n(41u'.05\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.f+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(g|u+\n(.Vu
.if (\n(g|+\n(#^-1v)>\n(#- .nr #- +(\n(g|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'YBT\h'|\n(41u'.05\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.g+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(h|u+\n(.Vu
.if (\n(h|+\n(#^-1v)>\n(#- .nr #- +(\n(h|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'SIDE\h'|\n(41u'0.9\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.h+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(i|u+\n(.Vu
.if (\n(i|+\n(#^-1v)>\n(#- .nr #- +(\n(i|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'NREP\h'|\n(41u'6\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.i+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(j|u+\n(.Vu
.if (\n(j|+\n(#^-1v)>\n(#- .nr #- +(\n(j|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'NCRT\h'|\n(41u'4\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.j+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(k|u+\n(.Vu
.if (\n(k|+\n(#^-1v)>\n(#- .nr #- +(\n(k|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'ILAB\h'|\n(41u'1\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.k+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(l|u+\n(.Vu
.if (\n(l|+\n(#^-1v)>\n(#- .nr #- +(\n(l|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'NULBLL\h'|\n(41u'3\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.l+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(m|u+\n(.Vu
.if (\n(m|+\n(#^-1v)>\n(#- .nr #- +(\n(m|+\n(#^-\n(#--1v)
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'IOFFD\h'|\n(41u'0\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.m+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.bp
.T&
.B
.ta \n(80u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'Name\h'|\n(41u'Default\h'|\n(42u'Function
.R
.sp
.ne \n(n|u+\n(.Vu
.if (\n(n|+\n(#^-1v)>\n(#- .nr #- +(\n(n|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'EXT\h'|\n(41u'.25\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.n+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(o|u+\n(.Vu
.if (\n(o|+\n(#^-1v)>\n(#- .nr #- +(\n(o|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'IOFFP\h'|\n(41u'0\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.o+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.ne \n(p|u+\n(.Vu
.if (\n(p|+\n(#^-1v)>\n(#- .nr #- +(\n(p|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'SPVAL\h'|\n(41u'0.\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.p+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(q|u+\n(.Vu
.if (\n(q|+\n(#^-1v)>\n(#- .nr #- +(\n(q|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'IOFFM\h'|\n(41u'0\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.q+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(r|u+\n(.Vu
.if (\n(r|+\n(#^-1v)>\n(#- .nr #- +(\n(r|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'ISOLID\h'|\n(41u'1023\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.r+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.sp
.ne \n(s|u+\n(.Vu
.if (\n(s|+\n(#^-1v)>\n(#- .nr #- +(\n(s|+\n(#^-\n(#--1v)
.ta \n(80u \n(61u \n(81u \n(84u 
.nr 31 \n(.f
.nr 35 1m
\&\h'|\n(40u'IHILO\h'|\n(41u'3\h'|\n(42u'
.mk ##
.nr 31 \n(##
.sp |\n(##u-1v
.nr 37 \n(42u
.in +\n(37u
.s+
.in -\n(37u
.mk 32
.if \n(32>\n(31 .nr 31 \n(32
.sp |\n(31u
.fc
.nr T. 1
.T# 1
.35
.rm a+
.rm b+
.rm c+
.rm d+
.rm e+
.rm f+
.rm g+
.rm h+
.rm i+
.rm j+
.rm k+
.rm l+
.rm m+
.rm n+
.rm o+
.rm p+
.rm q+
.rm r+
.rm s+
.TE
.if \n-(b.=0 .nr c. \n(.c-\n(d.-208
