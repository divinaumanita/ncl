C
C	$Id: arscam.f,v 1.1.1.1 1992-04-17 22:32:13 ncargd Exp $
C
C
C The subroutine ARSCAM.
C --- ---------- -------
C
      SUBROUTINE ARSCAM (IAM,XCS,YCS,MCS,IAI,IAG,MAI,APR)
C
      DIMENSION IAM(*),XCS(MCS),YCS(MCS),IAI(MAI),IAG(MAI)
C
C The routine ARSCAM is called to scan an area map created by calls to
C ARINAM and AREDAM.  For each subarea of the map, the user routine APR
C is called.
C
C IAM is the array holding the area map, created by prior calls to the
C routines ARINAM and AREDAM.
C
C The arrays XCS and YCS are used, in a call to APR, to hold the x
C and y coordinates of the points defining a particular subarea.  Each
C is dimensioned MCS.
C
C The arrays IAG and IAI are used, in a call to APR, to hold the
C group and area identifiers of the subarea defined by XCS and YCS.
C Each is dimensioned MAI.
C
C APR is the user's area-processing routine.  It must be declared in
C an EXTERNAL statement in the routine which calls ARSCAM.  It will be
C called using a FORTRAN statement like
C
C       CALL APR (XCS,YCS,NCS,IAI,IAG,NAI)
C
C where XCS and YCS hold the normalized device coordinates of NCS points
C defining a single subarea (point number NCS being a duplicate of point
C number 1) and IAI and IAG hold NAI area-identifier/group-identifier
C pairs for that subarea.
C
C Declare the AREAS common block.
C
C
C ARCOMN contains variables which are used by all the AREAS routines.
C
      COMMON /ARCOMN/ IAD,IAU,ILC,RLC,ILM,RLM,ILP,RLP,IBS,RBS,DBS,IDB,
     +                IDC,IDI
      SAVE   /ARCOMN/
C
C Declare the BLOCK DATA routine external, which should force it to
C load from a binary library.
C
      EXTERNAL ARBLDA
C
C Define some double-precision variables.
C
      DOUBLE PRECISION DP1,DP2
C
C Define the arrays which determine the multiple-precision operations
C to be done by ARMPIA.
C
      DIMENSION IO1(4,8),IO2(4,4)
C
      DATA IO1 / 1 ,  1 ,  0 ,  0 ,
     +           1 ,  2 ,  0 ,  0 ,
     +           1 ,  3 ,  0 ,  0 ,
     +           1 ,  4 ,  0 ,  0 ,
     +           4 ,  5 ,  1 ,  2 ,
     +           4 ,  6 ,  3 ,  4 ,
     +           3 ,  7 ,  5 ,  6 ,
     +           5 ,  7 ,  0 ,  0 /
      DATA IO2 / 4 ,  5 ,  1 ,  4 ,
     +           4 ,  6 ,  2 ,  3 ,
     +           2 ,  7 ,  5 ,  6 ,
     +           5 ,  7 ,  0 ,  0 /
C
C Pull out the length of the area map and check for initialization.
C
      LAM=IAM(1)
C
      IF (.NOT.(IAU.EQ.0.OR.IAM(LAM).NE.LAM)) GO TO 10001
        CALL SETER ('ARSCAM - INITIALIZATION DONE IMPROPERLY',1,1)
        RETURN
10001 CONTINUE
C
C Save the current user-system mapping and reset it as required for
C calls to APR.
C
      CALL GETSET (FFL,FFR,FFB,FFT,FUL,FUR,FUB,FUT,ILL)
      CALL SET    (FFL,FFR,FFB,FFT,FFL,FFR,FFB,FFT,  1)
C
C Initialize IPX, which is used to position nodes in coordinate order.
C
      IPX=8
C
C If it has not already been done, find points of intersection and
C incorporate them into the map and then adjust area identifiers.
C
      IF (IAM(4).EQ.0) CALL ARPRAM (IAM,0,0,0)
C
C We first make a pass over the entire area map, looking for holes and
C eliminating them by the insertion of some temporary connecting lines.
C
C Save the pointer to the last word of the last node, so that we can
C remove the nodes implementing the temporary connecting lines before
C returning to the caller.
C
      ILW=IAM(5)
C
C Each pass through the following loop traces the boundary of one
C connected loop.
C
C
      IPT=8
C
10002 CONTINUE
C
C Move to the right across the area map, looking for an edge segment
C that has not yet been completely processed.  If no such segment can
C be found, all subareas have been done.
C
10003   CONTINUE
        IF (.NOT.(IAM(IPT).GE.3.OR.IAM(IPT+7).LE.1)) GO TO 10004
          IPT=IAM(IPT+5)
          IF (IPT.EQ.18) GO TO 10005
        GO TO 10003
10004   CONTINUE
C
C Decide whether to scan the subarea to the left of the edge being
C traced (IPU=1) or the one to the right (IPU=2).
C
        IF (.NOT.(IAM(IPT).EQ.0.OR.IAM(IPT).EQ.2)) GO TO 10006
          IPU=1
        GO TO 10007
10006   CONTINUE
          IPU=2
10007   CONTINUE
C
C IPQ points to the node defining the beginning of the edge segment,
C IPR to the node defining the end of the edge segment, and IPS to
C the node defining the beginning of the edge, so that we can tell
C when we've gone all the way around it.
C
        IPQ=IAM(IPT+4)
        IPR=IPT
        IPS=IPQ
        IPM=IPR
        IPV=IPU
C
C We need to keep track of the highest point found along the loop and
C the total change in direction.  Initialize the variables involved.
C
        IPH=IPQ
        ANT=0.
C
C Each pass through the following loop moves one step along the edge of
C the subarea.
C
10008   CONTINUE
C
C Update the pointer to the highest point found along the loop.
C
          IF (IAM(IPR+2).GT.IAM(IPH+2)) IPH=IPR
C
C Move IPQ to IPP and IPR to IPQ.
C
          IPP=IPQ
          IPQ=IPR
C
C Get the coordinates of the ends of the edge segment for use in
C computing change in direction to a possible next point.
C
          IXP=IAM(IPP+1)
          IYP=IAM(IPP+2)
          IXQ=IAM(IPQ+1)
          IYQ=IAM(IPQ+2)
          FXP=REAL(IXP)
          FYP=REAL(IYP)
          FXQ=REAL(IXQ)
          FYQ=REAL(IYQ)
C
C Back up IPR to the beginning of the group of nodes which have the
C same x and y coordinates as it does.
C
10009     CONTINUE
          IF (.NOT.(IAM(IPR+1).EQ.IAM(IAM(IPR+6)+1).AND.IAM(IPR+2).EQ.IA
     +M(IAM(IPR+6)+2))) GO TO 10010
            IPR=IAM(IPR+6)
          GO TO 10009
10010     CONTINUE
C
C Go through the group of nodes, examining all the possible ways to
C move from the current position to a new one.  Pick the direction
C which is leftmost (if IPU=1) or rightmost (if IPU=2).
C
          IP1=IPR
          IP2=IPR
          IPR=0
          IF (.NOT.(IPU.EQ.1)) GO TO 10011
            ANM=-3.14159265358979
          GO TO 10012
10011     CONTINUE
            ANM=+3.14159265358979
10012     CONTINUE
C
10013     CONTINUE
          IF (.NOT.(IAM(IP2+1).EQ.IAM(IP1+1).AND.IAM(IP2+2).EQ.IAM(IP1+2
     +))) GO TO 10014
            IF (.NOT.(IAM(IAM(IP2+3)+7).GT.1.AND.(IAM(IAM(IP2+3)+1).NE.I
     +AM(IPP+1).OR.IAM(IAM(IP2+3)+2).NE.IAM(IPP+2)))) GO TO 10015
              IXR=IAM(IAM(IP2+3)+1)
              IYR=IAM(IAM(IP2+3)+2)
              FXR=REAL(IXR)
              FYR=REAL(IYR)
C
              IF (.NOT.(IAU.EQ.1)) GO TO 10016
                ANG=ARRAT2((FXQ-FXP)*(FYR-FYQ)-(FYQ-FYP)*(FXR-FXQ),
     +                     (FXQ-FXP)*(FXR-FXQ)+(FYQ-FYP)*(FYR-FYQ))
              GO TO 10017
10016         CONTINUE
              IF (.NOT.(IAU.EQ.2)) GO TO 10018
                ANG=ARDAT2(DBLE(IXQ-IXP)*DBLE(IYR-IYQ)-
     +                     DBLE(IYQ-IYP)*DBLE(IXR-IXQ),
     +                     DBLE(IXQ-IXP)*DBLE(IXR-IXQ)+
     +                     DBLE(IYQ-IYP)*DBLE(IYR-IYQ))
              GO TO 10017
10018         CONTINUE
                IO1(3,1)=IXQ-IXP
                IO1(3,2)=IYR-IYQ
                IO1(3,3)=IYQ-IYP
                IO1(3,4)=IXR-IXQ
                CALL ARMPIA (IO1,DP1)
                CALL ARMPIA (IO2,DP2)
                ANG=ARDAT2(DP1,DP2)
10017         CONTINUE
C
              IF (.NOT.(IPU.EQ.1)) GO TO 10019
                IF (.NOT.(ANG.GT.ANM)) GO TO 10020
                  IPR=IAM(IP2+3)
                  ANM=ANG
                  IPM=IPR
                  IPV=1
10020           CONTINUE
              GO TO 10021
10019         CONTINUE
                IF (.NOT.(ANG.LT.ANM)) GO TO 10022
                  IPR=IAM(IP2+3)
                  ANM=ANG
                  IPM=IPR
                  IPV=2
10022           CONTINUE
10021         CONTINUE
10015       CONTINUE
            IF (.NOT.(IAM(IP2+7).GT.1.AND.(IAM(IAM(IP2+4)+1).NE.IAM(IPP+
     +1).OR.IAM(IAM(IP2+4)+2).NE.IAM(IPP+2)))) GO TO 10023
              IXR=IAM(IAM(IP2+4)+1)
              IYR=IAM(IAM(IP2+4)+2)
              FXR=REAL(IXR)
              FYR=REAL(IYR)
C
              IF (.NOT.(IAU.EQ.1)) GO TO 10024
                ANG=ARRAT2((FXQ-FXP)*(FYR-FYQ)-(FYQ-FYP)*(FXR-FXQ),
     +                     (FXQ-FXP)*(FXR-FXQ)+(FYQ-FYP)*(FYR-FYQ))
              GO TO 10025
10024         CONTINUE
              IF (.NOT.(IAU.EQ.2)) GO TO 10026
                ANG=ARDAT2(DBLE(IXQ-IXP)*DBLE(IYR-IYQ)-
     +                     DBLE(IYQ-IYP)*DBLE(IXR-IXQ),
     +                     DBLE(IXQ-IXP)*DBLE(IXR-IXQ)+
     +                     DBLE(IYQ-IYP)*DBLE(IYR-IYQ))
              GO TO 10025
10026         CONTINUE
                IO1(3,1)=IXQ-IXP
                IO1(3,2)=IYR-IYQ
                IO1(3,3)=IYQ-IYP
                IO1(3,4)=IXR-IXQ
                CALL ARMPIA (IO1,DP1)
                CALL ARMPIA (IO2,DP2)
                ANG=ARDAT2(DP1,DP2)
10025         CONTINUE
C
              IF (.NOT.(IPU.EQ.1)) GO TO 10027
                IF (.NOT.(ANG.GT.ANM)) GO TO 10028
                  IPR=IAM(IP2+4)
                  ANM=ANG
                  IPM=IP2
                  IPV=2
10028           CONTINUE
              GO TO 10029
10027         CONTINUE
                IF (.NOT.(ANG.LT.ANM)) GO TO 10030
                  IPR=IAM(IP2+4)
                  ANM=ANG
                  IPM=IP2
                  IPV=1
10030           CONTINUE
10029         CONTINUE
10023       CONTINUE
            IP2=IAM(IP2+5)
          GO TO 10013
10014     CONTINUE
C
C If no possible exit was found, reverse direction.
C
          IF (.NOT.(IPR.EQ.0)) GO TO 10031
            IPR=IPP
            IPV=3-IPV
            IF (.NOT.(IPU.EQ.1)) GO TO 10032
              ANM=+3.14159265358979
            GO TO 10033
10032       CONTINUE
              ANM=-3.14159265358979
10033       CONTINUE
10031     CONTINUE
C
C Update the total angular change.
C
          ANT=ANT+ANM
C
C Update the markers for the edge segment picked.
C
          IF (.NOT.(IPV.EQ.1)) GO TO 10034
            IF (.NOT.(MOD(IAM(IPM),2).EQ.0)) GO TO 10035
              IAM(IPM)=IAM(IPM)+1
            GO TO 10036
10035       CONTINUE
              CALL SETER ('ARSCAM - ALGORITHM FAILURE',2,1)
              GO TO 10038
10036       CONTINUE
          GO TO 10039
10034     CONTINUE
            IF (.NOT.(MOD(IAM(IPM)/2,2).EQ.0)) GO TO 10040
              IAM(IPM)=IAM(IPM)+2
            GO TO 10041
10040       CONTINUE
              CALL SETER ('ARSCAM - ALGORITHM FAILURE',3,1)
              GO TO 10038
10041       CONTINUE
10039     CONTINUE
C
C Exit if we're passing the start of the subarea.
C
          IF (IAM(IPQ+1).EQ.IAM(IPS+1).AND.IAM(IPQ+2).EQ.IAM(IPS+2).AND.
     +IAM(IPR+1).EQ.IAM(IPT+1).AND.IAM(IPR+2).EQ.IAM(IPT+2)) GO TO 10043
C
        GO TO 10008
10043   CONTINUE
C
C If the closed loop just traced was a hole, insert a temporary
C connecting line to get rid of the hole.
C
        IF (.NOT.((IPU.EQ.1.AND.ANT.LT.0.).OR.(IPU.EQ.2.AND.ANT.GT.0.)))
     +  GO TO 10044
          IOF=0
          XCI=REAL(IAM(IPH+1))
          YCI=REAL(IAM(IPH+2))
          YCO=RLP
          IP1=IPH
10045     CONTINUE
          IF (.NOT.(IAM(IAM(IP1+5)+1).EQ.IAM(IPH+1))) GO TO 10046
            IP1=IAM(IP1+5)
          GO TO 10045
10046     CONTINUE
10047     CONTINUE
          IF (.NOT.(IAM(IP1+1).GE.IAM(IPH+1)-IAM(2))) GO TO 10048
            IF (.NOT.(IAM(IP1+7).GT.1.AND.IAM(IAM(IP1+4)+1).GT.IAM(IP1+1
     +).AND.IAM(IAM(IP1+4)+1).GE.IAM(IPH+1))) GO TO 10049
              IF (.NOT.(IAU.EQ.1)) GO TO 10050
                YTM=REAL(IAM(IP1+2))+
     +          (XCI-REAL(IAM(IP1+1)))*
     +       (REAL(IAM(IAM(IP1+4)+2)-IAM(IP1+2))/                      R
     +EAL(IAM(IAM(IP1+4)+1)-IAM(IP1+1)))
              GO TO 10051
10050         CONTINUE
                YTM=REAL(DBLE(IAM(IP1+2))+
     +          (DBLE(XCI)-DBLE(IAM(IP1+1)))*
     +       (DBLE(IAM(IAM(IP1+4)+2)-IAM(IP1+2))/                      D
     +BLE(IAM(IAM(IP1+4)+1)-IAM(IP1+1))))
10051         CONTINUE
              IF (.NOT.(YTM.GT.YCI.AND.YTM.LT.YCO)) GO TO 10052
                IOF=IP1
                YCO=YTM
10052         CONTINUE
10049       CONTINUE
            IF (.NOT.(IAM(IAM(IP1+3)+7).GT.1.AND.IAM(IAM(IP1+3)+1).GT.IA
     +M(IP1+1).AND.IAM(IAM(IP1+3)+1).GE.IAM(IPH+1))) GO TO 10053
              IF (.NOT.(IAU.EQ.1)) GO TO 10054
                YTM=REAL(IAM(IP1+2))+
     +          (XCI-REAL(IAM(IP1+1)))*
     +       (REAL(IAM(IAM(IP1+3)+2)-IAM(IP1+2))/                      R
     +EAL(IAM(IAM(IP1+3)+1)-IAM(IP1+1)))
              GO TO 10055
10054         CONTINUE
                YTM=REAL(DBLE(IAM(IP1+2))+
     +          (DBLE(XCI)-DBLE(IAM(IP1+1)))*
     +       (DBLE(IAM(IAM(IP1+3)+2)-IAM(IP1+2))/                      D
     +BLE(IAM(IAM(IP1+3)+1)-IAM(IP1+1))))
10055         CONTINUE
              IF (.NOT.(YTM.GT.YCI.AND.YTM.LT.YCO)) GO TO 10056
                IOF=IAM(IP1+3)
                YCO=YTM
10056         CONTINUE
10053       CONTINUE
            IP1=IAM(IP1+6)
          GO TO 10047
10048     CONTINUE
          IF (.NOT.(IOF.NE.0)) GO TO 10057
            IX0=IAM(IPH+1)
            IY0=IAM(IPH+2)
            IF (.NOT.(INT(YCO).NE.IY0)) GO TO 10058
              IPI=18
              ASSIGN 10059 TO L10060
              GO TO 10060
10059         CONTINUE
              IY0=INT(YCO)
              ASSIGN 10061 TO L10060
              GO TO 10060
10061         CONTINUE
              IAM(IPN+7)=1
10058       CONTINUE
            IF (.NOT.((IX0.NE.IAM(IOF+1).OR.IY0.NE.IAM(IOF+2)).AND.(IX0.
     +NE.IAM(IAM(IOF+4)+1).OR.IY0.NE.IAM(IAM(IOF+4)+2)))) GO TO 10062
              IPI=IOF
              ASSIGN 10063 TO L10060
              GO TO 10060
10063         CONTINUE
              IAM(IPN)=IAM(IPI)
              IAM(IPN+7)=IAM(IPI+7)
              IAM(IPN+8)=IAM(IPI+8)
              IAM(IPN+9)=IAM(IPI+9)
10062       CONTINUE
10057     CONTINUE
C
10044   CONTINUE
C
      GO TO 10002
10005 CONTINUE
C
C Zero the markers for all the nodes.
C
      DO 10064 IPT=8,IAM(5)-9,10
        IAM(IPT)=0
10064 CONTINUE
C
C
C Now, make a pass through the area map, tracing one subarea at a time
C and calling the routine APR to do with it what the user wants.
C
C Each pass through the following loop traces the boundary of one
C subarea.
C
C
      IPT=8
C
10065 CONTINUE
C
C Move to the right across the area map, looking for an edge segment
C that has not yet been completely processed.  If no such segment can
C be found, all subareas have been done.
C
10066   CONTINUE
        IF (.NOT.(IAM(IPT).GE.3.OR.IAM(IPT+7).LE.1)) GO TO 10067
          IPT=IAM(IPT+5)
          IF (IPT.EQ.18) GO TO 10068
        GO TO 10066
10067   CONTINUE
C
C Decide whether to scan the subarea to the left of the edge being
C traced (IPU=1) or the one to the right (IPU=2).
C
        IF (.NOT.(IAM(IPT).EQ.0.OR.IAM(IPT).EQ.2)) GO TO 10069
          IPU=1
          IAQ=IPT+8
        GO TO 10070
10069   CONTINUE
          IPU=2
          IAQ=IPT+9
10070   CONTINUE
C
C Store the first group identifier and area identifier for the subarea
C and clear the flag that is set when all identifiers have been found.
C
        NAI=1
        IAI(NAI)=IAM(IAQ)
        IF (IAI(NAI).GE.IAM(6)) IAI(NAI)=IAM(IAI(NAI))/2
        IAG(NAI)=IAM(IAM(IPT+7))/2
C
        IAF=0
C
C IPQ points to the node defining the beginning of the edge segment,
C IPR to the node defining the end of the edge segment, and IPS to
C the node defining the beginning of the edge, so that we can tell
C when we've gone all the way around it.
C
        IPQ=IAM(IPT+4)
        IPR=IPT
        IPS=IPQ
        IPM=IPR
        IPV=IPU
C
C Put the first point in the list defining this subarea.
C
        NCS=1
        XCS(1)=REAL(IAM(IPQ+1))/RLC
        YCS(1)=REAL(IAM(IPQ+2))/RLC
C
C Each pass through the following loop moves one step along the edge of
C the subarea.
C
10071   CONTINUE
C
C Add the end of the current segment to the description of the subarea.
C
          IF (.NOT.(NCS.LT.MCS)) GO TO 10072
            NCS=NCS+1
            XCS(NCS)=REAL(IAM(IPR+1))/RLC
            YCS(NCS)=REAL(IAM(IPR+2))/RLC
          GO TO 10073
10072     CONTINUE
            CALL SETER ('ARSCAM - MCS TOO SMALL',4,1)
            GO TO 10038
10073     CONTINUE
C
C If the group/area identifier information is incomplete and the current
C edge segment spans a portion of the x axis of non-zero length, scan
C outwards from the subarea for group/area identifier information.
C
          IF (.NOT.(IAF.EQ.0.AND.IAM(IPQ+1).NE.IAM(IPR+1))) GO TO 10075
C
            IF (.NOT.(IAM(IPQ+1).LT.IAM(IPR+1))) GO TO 10076
              IP1=IPQ
              IP2=IPR
              IDU=3-IPU
            GO TO 10077
10076       CONTINUE
              IP1=IPR
              IP2=IPQ
              IDU=IPU
10077       CONTINUE
C
            IXC=INT(.5*(REAL(IAM(IP1+1))+REAL(IAM(IP2+1))))
            XCO=REAL(IXC)+.5
            IF (.NOT.(IAU.EQ.1)) GO TO 10078
              YCO=REAL(IAM(IP1+2))+(XCO-REAL(IAM(IP1+1)))*
     +     (REAL(IAM(IP2+2)-IAM(IP1+2))/
     +REAL(IAM(IP2+1)-IAM(IP1+1)))
            GO TO 10079
10078       CONTINUE
              YCO=REAL(DBLE(IAM(IP1+2))+
     +        (DBLE(XCO)-DBLE(IAM(IP1+1)))*
     +     (DBLE(IAM(IP2+2)-IAM(IP1+2))/
     +DBLE(IAM(IP2+1)-IAM(IP1+1))))
10079       CONTINUE
C
            IGI=LAM
C
10080       CONTINUE
            IF (.NOT.(IGI.GT.IAM(6))) GO TO 10081
              IGI=IGI-1
              IF (.NOT.(MOD(IAM(IGI),2).EQ.0.AND.IAM(IPT+7).NE.IGI)) GO
     +TO 10082
                IAF=0
                IF (.NOT.(IDU.EQ.1)) GO TO 10083
                  YCI=RLP
                GO TO 10084
10083           CONTINUE
                  YCI=-1.
10084           CONTINUE
                IP3=IAM(IP2+6)
10085           CONTINUE
                IF (.NOT.(IAM(IP3+1)+IAM(2).GT.IXC)) GO TO 10086
                  IF (.NOT.(IAM(IP3+1).LE.IXC)) GO TO 10087
                    IF (.NOT.(ABS(IAM(IP3+7)).EQ.IGI.AND.IAM(IP3+1).LT.I
     +AM(IAM(IP3+4)+1).AND.IXC.LT.IAM(IAM(IP3+4)+1))) GO TO 10088
                      IF (.NOT.(IAU.EQ.1)) GO TO 10089
                        YTM=REAL(IAM(IP3+2))+
     +                  (XCO-REAL(IAM(IP3+1)))*
     +               (REAL(IAM(IAM(IP3+4)+2)-
     +                   IAM(IP3      +2))/
     +       REAL(IAM(IAM(IP3+4)+1)-
     +          IAM(IP3      +1)))
                      GO TO 10090
10089                 CONTINUE
                        YTM=REAL(DBLE(IAM(IP3+2))+
     +                  (DBLE(XCO)-DBLE(IAM(IP3+1)))*
     +               (DBLE(IAM(IAM(IP3+4)+2)-
     +                   IAM(IP3      +2))/
     +       DBLE(IAM(IAM(IP3+4)+1)-
     +          IAM(IP3      +1))))
10090                 CONTINUE
                      IF (.NOT.(IDU.EQ.1.AND.YTM.LT.YCI.AND.YTM.GE.YCO))
     + GO TO 10091
                        IAF=IP3
                        IAQ=IAF+8
                        YCI=YTM
10091                 CONTINUE
                      IF (.NOT.(IDU.EQ.2.AND.YTM.GT.YCI.AND.YTM.LE.YCO))
     + GO TO 10092
                        IAF=IP3
                        IAQ=IAF+9
                        YCI=YTM
10092                 CONTINUE
10088               CONTINUE
                    IF (.NOT.(ABS(IAM(IAM(IP3+3)+7)).EQ.IGI.AND.IAM(IP3+
     +1).LT.IAM(IAM(IP3+3)+1).AND.IXC.LT.IAM(IAM(IP3+3)+1))) GO TO 10093
                      IF (.NOT.(IAU.EQ.1)) GO TO 10094
                        YTM=REAL(IAM(IP3+2))+
     +                  (XCO-REAL(IAM(IP3+1)))*
     +               (REAL(IAM(IAM(IP3+3)+2)-
     +                   IAM(IP3      +2))/
     +       REAL(IAM(IAM(IP3+3)+1)-
     +          IAM(IP3      +1)))
                      GO TO 10095
10094                 CONTINUE
                        YTM=REAL(DBLE(IAM(IP3+2))+
     +                  (DBLE(XCO)-DBLE(IAM(IP3+1)))*
     +               (DBLE(IAM(IAM(IP3+3)+2)-
     +                   IAM(IP3      +2))/
     +       DBLE(IAM(IAM(IP3+3)+1)-
     +          IAM(IP3      +1))))
10095                 CONTINUE
                      IF (.NOT.(IDU.EQ.1.AND.YTM.LT.YCI.AND.YTM.GE.YCO))
     + GO TO 10096
                        IAF=IAM(IP3+3)
                        IAQ=IAF+9
                        YCI=YTM
10096                 CONTINUE
                      IF (.NOT.(IDU.EQ.2.AND.YTM.GT.YCI.AND.YTM.LE.YCO))
     + GO TO 10097
                        IAF=IAM(IP3+3)
                        IAQ=IAF+8
                        YCI=YTM
10097                 CONTINUE
10093               CONTINUE
10087             CONTINUE
                  IP3=IAM(IP3+6)
                GO TO 10085
10086           CONTINUE
                IF (.NOT.(IAF.NE.0)) GO TO 10098
                  IF (.NOT.(NAI.LT.MAI)) GO TO 10099
                    NAI=NAI+1
                    IF (.NOT.(IAM(IAQ).LT.IAM(6))) GO TO 10100
                      IAI(NAI)=IAM(IAQ)
                    GO TO 10101
10100               CONTINUE
                      IAI(NAI)=IAM(IAM(IAQ))/2
10101               CONTINUE
                    IAG(NAI)=IAM(IGI)/2
                  GO TO 10102
10099             CONTINUE
                    CALL SETER ('ARSCAM - MAI TOO SMALL',5,1)
                    GO TO 10038
10102             CONTINUE
10098           CONTINUE
10082         CONTINUE
            GO TO 10080
10081       CONTINUE
            IAF=1
C
10075     CONTINUE
C
C Move IPQ to IPP and IPR to IPQ.
C
          IPP=IPQ
          IPQ=IPR
C
C Get the coordinates of the ends of the edge segment for use in
C computing change in direction to a possible next point.
C
          IXP=IAM(IPP+1)
          IYP=IAM(IPP+2)
          IXQ=IAM(IPQ+1)
          IYQ=IAM(IPQ+2)
          FXP=REAL(IXP)
          FYP=REAL(IYP)
          FXQ=REAL(IXQ)
          FYQ=REAL(IYQ)
C
C Back up IPR to the beginning of the group of nodes which have the
C same x and y coordinates as it does.
C
10104     CONTINUE
          IF (.NOT.(IAM(IPR+1).EQ.IAM(IAM(IPR+6)+1).AND.IAM(IPR+2).EQ.IA
     +M(IAM(IPR+6)+2))) GO TO 10105
            IPR=IAM(IPR+6)
          GO TO 10104
10105     CONTINUE
C
C If there is only one node in the group, the exit path is obvious.
C
          IF (.NOT.(IAM(IPR+1).NE.IAM(IAM(IPR+5)+1).OR.IAM(IPR+2).NE.IAM
     +(IAM(IPR+5)+2))) GO TO 10106
            IF (.NOT.(IAM(IAM(IPR+3)+1).NE.IAM(IPP+1).OR.IAM(IAM(IPR+3)+
     +2).NE.IAM(IPP+2))) GO TO 10107
              IF (.NOT.(IAM(IAM(IPR+3)+7).GT.0)) GO TO 10108
                IPM=IAM(IPR+3)
                IPR=IPM
                IPV=IPU
              GO TO 10109
10108         CONTINUE
                IPR=0
10109         CONTINUE
            GO TO 10110
10107       CONTINUE
              IF (.NOT.(IAM(IPR+7).GT.0)) GO TO 10111
                IPM=IPR
                IPR=IAM(IPR+4)
                IPV=3-IPU
              GO TO 10112
10111         CONTINUE
                IPR=0
10112         CONTINUE
10110       CONTINUE
C
C Otherwise, go through the group of nodes, examining all the possible
C ways to move from the current position to a new one.  Pick the
C direction which is leftmost (if IPU=1) or rightmost (if IPU=2).
C
          GO TO 10113
10106     CONTINUE
C
            IP1=IPR
            IP2=IPR
            IPR=0
            IF (.NOT.(IPU.EQ.1)) GO TO 10114
              ANM=-3.14159265358979
            GO TO 10115
10114       CONTINUE
              ANM=+3.14159265358979
10115       CONTINUE
C
10116       CONTINUE
            IF (.NOT.(IAM(IP2+1).EQ.IAM(IP1+1).AND.IAM(IP2+2).EQ.IAM(IP1
     ++2))) GO TO 10117
              IF (.NOT.(IAM(IAM(IP2+3)+7).GT.0.AND.(IAM(IAM(IP2+3)+1).NE
     +.IAM(IPP+1).OR.IAM(IAM(IP2+3)+2).NE.IAM(IPP+2)))) GO TO 10118
                IXR=IAM(IAM(IP2+3)+1)
                IYR=IAM(IAM(IP2+3)+2)
                FXR=REAL(IXR)
                FYR=REAL(IYR)
C
                IF (.NOT.(IAU.EQ.1)) GO TO 10119
                  ANG=ARRAT2((FXQ-FXP)*(FYR-FYQ)-(FYQ-FYP)*(FXR-FXQ),
     +                       (FXQ-FXP)*(FXR-FXQ)+(FYQ-FYP)*(FYR-FYQ))
                GO TO 10120
10119           CONTINUE
                IF (.NOT.(IAU.EQ.2)) GO TO 10121
                  ANG=ARDAT2(DBLE(IXQ-IXP)*DBLE(IYR-IYQ)-
     +                       DBLE(IYQ-IYP)*DBLE(IXR-IXQ),
     +                       DBLE(IXQ-IXP)*DBLE(IXR-IXQ)+
     +                       DBLE(IYQ-IYP)*DBLE(IYR-IYQ))
                GO TO 10120
10121           CONTINUE
                  IO1(3,1)=IXQ-IXP
                  IO1(3,2)=IYR-IYQ
                  IO1(3,3)=IYQ-IYP
                  IO1(3,4)=IXR-IXQ
                  CALL ARMPIA (IO1,DP1)
                  CALL ARMPIA (IO2,DP2)
                  ANG=ARDAT2(DP1,DP2)
10120           CONTINUE
C
                IF (.NOT.(IPU.EQ.1)) GO TO 10122
                  IF (.NOT.(ANG.GT.ANM)) GO TO 10123
                    IPR=IAM(IP2+3)
                    ANM=ANG
                    IPM=IPR
                    IPV=1
10123             CONTINUE
                GO TO 10124
10122           CONTINUE
                  IF (.NOT.(ANG.LT.ANM)) GO TO 10125
                    IPR=IAM(IP2+3)
                    ANM=ANG
                    IPM=IPR
                    IPV=2
10125             CONTINUE
10124           CONTINUE
10118         CONTINUE
              IF (.NOT.(IAM(IP2+7).GT.0.AND.(IAM(IAM(IP2+4)+1).NE.IAM(IP
     +P+1).OR.IAM(IAM(IP2+4)+2).NE.IAM(IPP+2)))) GO TO 10126
                IXR=IAM(IAM(IP2+4)+1)
                IYR=IAM(IAM(IP2+4)+2)
                FXR=REAL(IXR)
                FYR=REAL(IYR)
C
                IF (.NOT.(IAU.EQ.1)) GO TO 10127
                  ANG=ARRAT2((FXQ-FXP)*(FYR-FYQ)-(FYQ-FYP)*(FXR-FXQ),
     +                       (FXQ-FXP)*(FXR-FXQ)+(FYQ-FYP)*(FYR-FYQ))
                GO TO 10128
10127           CONTINUE
                IF (.NOT.(IAU.EQ.2)) GO TO 10129
                  ANG=ARDAT2(DBLE(IXQ-IXP)*DBLE(IYR-IYQ)-
     +                       DBLE(IYQ-IYP)*DBLE(IXR-IXQ),
     +                       DBLE(IXQ-IXP)*DBLE(IXR-IXQ)+
     +                       DBLE(IYQ-IYP)*DBLE(IYR-IYQ))
                GO TO 10128
10129           CONTINUE
                  IO1(3,1)=IXQ-IXP
                  IO1(3,2)=IYR-IYQ
                  IO1(3,3)=IYQ-IYP
                  IO1(3,4)=IXR-IXQ
                  CALL ARMPIA (IO1,DP1)
                  CALL ARMPIA (IO2,DP2)
                  ANG=ARDAT2(DP1,DP2)
10128           CONTINUE
C
                IF (.NOT.(IPU.EQ.1)) GO TO 10130
                  IF (.NOT.(ANG.GT.ANM)) GO TO 10131
                    IPR=IAM(IP2+4)
                    ANM=ANG
                    IPM=IP2
                    IPV=2
10131             CONTINUE
                GO TO 10132
10130           CONTINUE
                  IF (.NOT.(ANG.LT.ANM)) GO TO 10133
                    IPR=IAM(IP2+4)
                    ANM=ANG
                    IPM=IP2
                    IPV=1
10133             CONTINUE
10132           CONTINUE
10126         CONTINUE
              IP2=IAM(IP2+5)
            GO TO 10116
10117       CONTINUE
C
10113     CONTINUE
C
C If no possible exit was found, reverse direction.
C
          IF (.NOT.(IPR.EQ.0)) GO TO 10134
            IPR=IPP
            IPV=3-IPV
10134     CONTINUE
C
C Update the markers for the edge segment picked.
C
          IF (.NOT.(IPV.EQ.1)) GO TO 10135
            IF (.NOT.(MOD(IAM(IPM),2).EQ.0)) GO TO 10136
              IAM(IPM)=IAM(IPM)+1
            GO TO 10137
10136       CONTINUE
              CALL SETER ('ARSCAM - ALGORITHM FAILURE',6,1)
              GO TO 10038
10137       CONTINUE
          GO TO 10139
10135     CONTINUE
            IF (.NOT.(MOD(IAM(IPM)/2,2).EQ.0)) GO TO 10140
              IAM(IPM)=IAM(IPM)+2
            GO TO 10141
10140       CONTINUE
              CALL SETER ('ARSCAM - ALGORITHM FAILURE',7,1)
              GO TO 10038
10141       CONTINUE
10139     CONTINUE
C
C Exit if we're passing the start of the subarea.
C
          IF (IAM(IPQ+1).EQ.IAM(IPS+1).AND.IAM(IPQ+2).EQ.IAM(IPS+2).AND.
     +IAM(IPR+1).EQ.IAM(IPT+1).AND.IAM(IPR+2).EQ.IAM(IPT+2)) GO TO 10143
C
        GO TO 10071
10143   CONTINUE
C
C A complete subarea has been found.  Let the user do what he wants
C with it.
C
        IF (.NOT.(NAI.EQ.IAM(7))) GO TO 10144
          IDI=IPU
          CALL APR (XCS,YCS,NCS,IAI,IAG,NAI)
        GO TO 10145
10144   CONTINUE
          IF (.NOT.(IAF.NE.0)) GO TO 10146
            CALL SETER ('ARSCAM - ALGORITHM FAILURE',8,1)
            GO TO 10038
10146     CONTINUE
10145   CONTINUE
C
      GO TO 10065
10068 CONTINUE
C
C Delete the nodes used to put in the temporary connecting lines.
C
      IPT=IAM(5)-9
10148 CONTINUE
      IF (.NOT.(IPT.GT.ILW)) GO TO 10149
        IAM(IAM(IPT+4)+3)=IAM(IPT+3)
        IAM(IAM(IPT+3)+4)=IAM(IPT+4)
        IAM(IAM(IPT+6)+5)=IAM(IPT+5)
        IAM(IAM(IPT+5)+6)=IAM(IPT+6)
        IPT=IPT-10
      GO TO 10148
10149 CONTINUE
      IAM(5)=ILW
C
C Zero the markers in all the remaining nodes.
C
      DO 10150 IPT=8,IAM(5)-9,10
        IAM(IPT)=0
10150 CONTINUE
C
C
C Done.
C
      GO TO 10038
C
C This internal procedure adds a new point in the existing part of the
C area map.
C
10060 CONTINUE
        IPN=IAM(5)+1
        IF (.NOT.(IAM(5)+10.GE.IAM(6))) GO TO 10152
          CALL SETER ('ARSCAM - AREA-MAP ARRAY OVERFLOW',9,1)
          GO TO 10038
10152   CONTINUE
        IAM(5)=IAM(5)+10
        IAM(IPN)=0
        IAM(IPN+1)=IX0
        IAM(IPN+2)=IY0
        IAM(IPN+3)=IPI
        IAM(IPN+4)=IAM(IPI+4)
        IAM(IAM(IPI+4)+3)=IPN
        IAM(IPI+4)=IPN
10154   CONTINUE
          IF (.NOT.(IAM(IPN+1).LT.IAM(IPX+1))) GO TO 10155
            IPX=IAM(IPX+6)
          GO TO 10156
10155     CONTINUE
          IF (.NOT.(IAM(IPN+1).GT.IAM(IAM(IPX+5)+1))) GO TO 10157
            IPX=IAM(IPX+5)
          GO TO 10156
10157     CONTINUE
10158       CONTINUE
              IF (.NOT.(IAM(IPN+1).EQ.IAM(IPX+1).AND.IAM(IPN+2).LT.IAM(I
     +PX+2))) GO TO 10159
                IPX=IAM(IPX+6)
              GO TO 10160
10159         CONTINUE
              IF (.NOT.(IAM(IPN+1).EQ.IAM(IAM(IPX+5)+1).AND.IAM(IPN+2).G
     +T.IAM(IAM(IPX+5)+2))) GO TO 10161
                IPX=IAM(IPX+5)
              GO TO 10160
10161         CONTINUE
                GO TO 10162
10160         CONTINUE
            GO TO 10158
10162       CONTINUE
            GO TO 10163
10156     CONTINUE
        GO TO 10154
10163   CONTINUE
        IAM(IPN+5)=IAM(IPX+5)
        IAM(IPN+6)=IAM(IAM(IPX+5)+6)
        IAM(IAM(IPX+5)+6)=IPN
        IAM(IPX+5)=IPN
        IAM(IPN+7)=0
        IAM(IPN+8)=0
        IAM(IPN+9)=0
      GO TO L10060 , (10063,10061,10059)
C
C Restore the original SET parameters and return to the caller.
C
10038 CONTINUE
        CALL SET (FFL,FFR,FFB,FFT,FUL,FUR,FUB,FUT,ILL)
        RETURN
C
      END
