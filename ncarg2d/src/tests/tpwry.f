C
C	$Id: tpwry.f,v 1.1.1.1 1992-04-17 22:33:30 ncargd Exp $
C
      SUBROUTINE TPWRY (IERROR)
C
C PURPOSE                To provide a simple demonstration of
C                        entry PWRITY.
C
C USAGE                  CALL TPWRY (IERROR)
C
C ARGUMENTS
C
C ON OUTPUT              IERROR
C                          An integer variable
C                          = 0, if the test was successful,
C                          = 1, otherwise
C
C I/O                    If the test is successful, the message
C
C               PWRITY TEST EXECUTED--SEE PLOTS TO CERTIFY
C
C                        is printed on unit 6.  In addition, 1
C                        frame is produced on the machine graphics
C                        device.  In order to determine if the test
C                        was successful, it is necessary to examine
C                        the plot.
C
C PRECISION              Single
C
C LANGUAGE               FORTRAN 77
C
C REQUIRED ROUTINES      PWRITY
C
C REQUIRED GKS LEVEL     0A
C
C Initialize the error parameter.
C
      IERROR = 0
C
C Define normalization transformation 1 and log scaling.
C
      CALL SET(0.0, 1.0, 0.0, 1.0,1.0, 1024.0, 1.0, 1024.0,1)
C
C Label the frame.
C
      CALL PWRITY(512.0,950.0,
     1            'DEMONSTRATION PLOT FOR PWRITY',
     2            29,2,0,0)
C
C Test PWRITY for different size characters.
C
      CALL PWRITY (10.0,900.0,'SIZE TEST',9,0,0,-1)
      CALL PWRITY (10.0,850.0,'SIZE TEST',9,1,0,-1)
      CALL PWRITY (10.0,775.0,'SIZE TEST',9,2,0,-1)
      CALL PWRITY (10.0,675.0,'SIZE TEST',9,3,0,-1)
      CALL PWRITY (10.0,525.0,'SIZE TEST',9,4,0,-1)
      CALL PWRITY (10.0,375.0,'SIZE TEST',9,5,0,-1)
C
C Test PWRITY for different character orientations.
C
      CALL PWRITY (600.0,600.0,'THETA TEST',10,2,0*90,-1)
      CALL PWRITY (600.0,600.0,'THETA TEST',10,2,1*90,-1)
      CALL PWRITY (600.0,600.0,'THETA TEST',10,2,2*90,-1)
      CALL PWRITY (600.0,600.0,'THETA TEST',10,2,3*90,-1)
C
C Test various centering options.
C
      CALL PWRITY (512.0,160.0,'CENTR TEST',10,2,0,0)
      CALL PWRITY (512.0,85.0,'CENTR TEST',10,2,0,-1)
      CALL PWRITY (512.0,235.0,'CENTR TEST',10,2,0,1)
      CALL FRAME
C
      WRITE (6,1001)
      RETURN
C
 1001 FORMAT (' PWRITY TEST EXECUTED--SEE PLOTS TO CERTIFY')
C
      END
