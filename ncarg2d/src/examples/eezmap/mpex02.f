C
C	$Id: mpex02.f,v 1.1.1.1 1992-04-17 22:33:13 ncargd Exp $
C
      PROGRAM EXMPL2
C
C This program produces a nice view of Africa, with an elliptical
C perimeter.
C
C Define the label for the top of the map.
C
      CHARACTER*26 PLBL
C
      DATA PLBL / 'CAN YOU NAME THE COUNTRIES' /
C
C Open GKS.
C
      CALL OPNGKS
C
C Use an elliptical perimeter.
C
      CALL MAPSTI ('EL',1)
C
C Dot the outlines, using dots a quarter as far apart as the default.
C
      CALL MAPSTI ('DO',1)
      CALL MAPSTI ('DD',3)
C
C Show continents and international boundaries.
C
      CALL MAPSTC ('OU','PO')
C
C Use a stereographic projection.
C
      CALL MAPROJ ('ST',0.,0.,0.)
C
C Specify where two corners of the map are.
C
      CALL MAPSET ('CO',-38.,-28.,40.,62.)
C
C Draw the map.
C
      CALL MAPDRW
C
C Put the label at the top of the plot.
C
      CALL SET (0.,1.,0.,1.,0.,1.,0.,1.,1)
      CALL PWRIT (.5,.975,PLBL,26,2,0,0)
C
C Draw a boundary around the edge of the plotter frame.
C
      CALL BNDARY
C
C Advance the frame.
C
      CALL FRAME
C
C Close GKS.
C
      CALL CLSGKS
C
C Done.
C
      STOP
C
      END
