C
C	$Id: mpex06.f,v 1.1.1.1 1992-04-17 22:33:13 ncargd Exp $
C
      PROGRAM EXMPL6
C
C This program produces a single frame showing satellite views
C of the globe, each rotated by a different angle.
C
C Define the label for the top of the map.
C
      CHARACTER*27 PLBL
C
      DATA PLBL / 'THE EARTH IS SPINNING, TOTO' /
C
C Open GKS.
C
      CALL OPNGKS
C
C Set the outline-dataset parameter.
C
      CALL MAPSTC ('OU','PS')
C
C Use a satellite-view projection.
C
      CALL MAPSTR ('SA',1.25)
C
C Aim the camera 15 degrees away from straight down.
C
      CALL MAPSTI ('S1',15)
C
C Turn off the perimeter and reduce the number of grid lines.
C
      CALL MAPSTI ('PE',0)
      CALL MAPSTI ('GR',15)
C
C Center the first map over Kansas.  Rotate by 0 degrees and look
C to the upper left.
C
      CALL MAPPOS (.05,.475,.525,.95)
      CALL MAPROJ ('SV',38.,-98.,0.)
      CALL MAPSTI ('S2',135)
      CALL MAPDRW
C
C Repeat, but rotate by 90 degrees and look to the upper right.
C
      CALL MAPPOS (.525,.95,.525,.95)
      CALL MAPROJ ('SV',38.,-98.,90.)
      CALL MAPSTI ('S2',45)
      CALL MAPDRW
C
C Repeat, but rotate by 180 degrees and look to the lower left.
C
      CALL MAPPOS (.05,.475,.05,.475)
      CALL MAPROJ ('SV',38.,-98.,180.)
      CALL MAPSTI ('S2',-135)
      CALL MAPDRW
C
C Repeat, but rotate by 270 degrees and look to the lower right.
C
      CALL MAPPOS (.525,.95,.05,.475)
      CALL MAPROJ ('SV',38.,-98.,270.)
      CALL MAPSTI ('S2',-45)
      CALL MAPDRW
C
C Put the label at the top of the plot ...
C
      CALL SET (0.,1.,0.,1.,0.,1.,0.,1.,1)
      CALL PWRIT (.5,.975,PLBL,27,2,0,0)
C
C and the ones below each sub-plot.
C
      CALL PWRIT (.2625,.5,'ROTA = 0',8,1,0,0)
      CALL PWRIT (.7375,.5,'ROTA = 90',9,1,0,0)
      CALL PWRIT (.2625,.025,'ROTA = 180',10,1,0,0)
      CALL PWRIT (.7375,.025,'ROTA = 270',10,1,0,0)
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
