@lazyglobal off.

{

global T_Rendezvous is lexicon(
  "CompleteRendezvous", CompleteRendezvous@
  ).

local FinalMan is "x".

Function EnsureSmallerOrbit {
  Parameter TargetDestination.

  if ship:orbit:periapsis > TargetDestination:orbit:periapsis {
    local DvNeeded is T_Other["VisViva"](ship:orbit:apoapsis, (ship:orbit:apoapsis + 0.9*TargetDestination:periapsis)/2 + ship:body:radius).
    local LowerList1 is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
    D_ManExe["DvCalc"](LowerList1).
    D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
    D_ManExe["PerformBurn"](EndDv, StartT).
  }

  if ship:orbit:apoapsis > TargetDestination:orbit:apoapsis {
    local DvNeeded is T_Other["VisViva"](ship:orbit:periapsis, (ship:orbit:periapsis + 0.9*TargetDestination:apoapsis)/2 + ship:body:radius).
    local LowerList2 is list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    D_ManExe["DvCalc"](LowerList2).
    D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
    D_ManExe["PerformBurn"](EndDv, StartT).
  }
}

Function RendezvousSetup {

  parameter TargetDestination.

      local ArgOfPer1 is ship:orbit:argumentofperiapsis.
      local ArgOfPer2 is TargetDestination:orbit:argumentofperiapsis.
      local TrueAnomalyTargetPer is ArgOfPer2-ArgOfPer1.

      local TimeTargetPeriapsis is T_TrueAnomaly["ETAToTrueAnomaly"](ship, TrueAnomalyTargetPer).

      //print "Time till target periapsis:   " + TimeTargetPeriapsis.

      local SMA is ship:orbit:semimajoraxis.
      local Ecc is ship:orbit:eccentricity.
      local CurRadiusAtTargetPeriapsis is (SMA * ( (1-ecc^2) / (1+ecc*cos(TrueAnomalyTargetPer))))-body:radius.

      if ship:orbit:semimajoraxis < TargetDestination:orbit:semimajoraxis {
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to T_HillUni["ResultFinder"](InputList, "ApoapsisMatch", NewScoreList, NewRestrictionList).
      } else {
        local InputList is list(time:seconds + TimeTargetPeriapsis, 0, 0, 0).
        local NewScoreList is list(TargetDestination).
        local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
        set FinalMan to T_HillUni["ResultFinder"](InputList, "PerApoMatch", NewScoreList, NewRestrictionList).
      }

      D_ManExe["DvCalc"](FinalMan).
      D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
      D_ManExe["PerformBurn"](EndDv, StartT).
}

Function MatchOrbit {
  Parameter TargetDestination.

  local ThetaChange is T_Inclination["RelativeAngleCalculation"](TargetDestination).

  print "Matching inclination".

  until ThetaChange < 0.04 {
   T_Inclination["InclinationMatcher"](TargetDestination).
   set ThetaChange to T_Inclination["RelativeAngleCalculation"](TargetDestination).
  }

  EnsureSmallerOrbit(TargetDestination).

  print "Circularizing".

  if ship:orbit:eccentricity > 0.00001 {
    if ship:orbit:apoapsis > TargetDestination:orbit:periapsis {
      local InputList is list(time:seconds + eta:periapsis, 0, 0, 0).
      local NewScoreList is list(TargetDestination).
      local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal").
      set FinalMan to T_HillUni["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
    } else {
      local InputList is list(time:seconds + eta:apoapsis, 0, 0, 0).
      local NewScoreList is list(TargetDestination).
      local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal").
      set FinalMan to T_HillUni["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
    }
    D_ManExe["DvCalc"](FinalMan).
    D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
    D_ManExe["PerformBurn"](EndDv, StartT).
  }



  print "Rendezvous approach".

  RendezvousSetup(TargetDestination).


  if ship:orbit:periapsis*1.05 > TargetDestination:orbit:apoapsis {
    print "lowering orbit".
    local DvNeeded is T_Other["VisViva"](ship:orbit:periapsis, (ship:orbit:periapsis+2*ship:body:radius+(0.8*TargetDestination:orbit:periapsis))/2).
    local LowerList is list(time:seconds+eta:periapsis, 0, 0, DvNeeded).
    D_ManExe["DvCalc"](LowerList).
    D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
    D_ManExe["PerformBurn"](EndDv, StartT).
  }

    print "Matching up orbit".
    local InputList is list(time:seconds + eta:apoapsis, 0, 0, 0).
    local NewScoreList is list(TargetDestination).
    local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal_radialout_radialin_timeplus_timemin").
    set FinalMan to T_HillUni["ResultFinder"](InputList, "PerPerMatch", NewScoreList, NewRestrictionList).
    D_ManExe["DvCalc"](FinalMan).
    D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
    D_ManExe["PerformBurn"](EndDv, StartT).
}

Function FinalApproach {
  Parameter TargetDestination.
  Parameter StepsNeeded is 1.

  local TimeTillDesiredTrueAnomaly is T_TrueAnomaly["ETAToTrueAnomaly"](TargetDestination, 180, eta:apoapsis).

  local CurPeriod is ship:orbit:period.
  local TarPeriod is CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

  local TarSMA is (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

  local DvNeeded is T_Other["VisViva"](ship:orbit:apoapsis, TarSMA).
  local AproachList is list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
  D_ManExe["DvCalc"](AproachList).

  if nextnode:orbit:hasnextpatch {
    if nextnode:orbit:nextpatch:body <> ship:orbit:body{
      until nextnode:orbit:nextpatch:body = ship:orbit:body{
        remove nextnode.
        set StepsNeeded to StepsNeeded + 1.

        set CurPeriod to ship:orbit:period.
        set TarPeriod to CurPeriod + (TimeTillDesiredTrueAnomaly/StepsNeeded).

        set TarSMA to (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).

        local DvNeeded is T_Other["VisViva"](ship:orbit:apoapsis, TarSMA).
        set AproachList to list(time:seconds+eta:apoapsis, 0, 0, DvNeeded).
        D_ManExe["DvCalc"](AproachList).
      }
    }
  }

  D_ManExe["TimeTillManeuverBurn"](FinalManeuver:eta, DvNeeded).
  D_ManExe["PerformBurn"](EndDv, StartT).

  wait 5.
  local TargetTime is "x".
  if StepsNeeded > 1 {
    set TargetTime to time:seconds + (StepsNeeded-1)*ship:orbit:period.
    warpto(TargetTime).
  } else {
    set TargetTime to time:seconds + 0.75*ship:orbit:period.
    warpto(TargetTime).
  }
  //print "warping some more".
  wait until time:seconds > TargetTime.
  wait 5.
  local TimeTillDesiredTrueAnomaly is T_TrueAnomaly["ETAToTrueAnomaly"](TargetDestination, 180).
  set TargetTime to time:seconds+TimeTillDesiredTrueAnomaly.
  warpto(TargetTime).
  //print "warped some more".
  wait until time:seconds > TargetTime.
  wait 7.

  local Distance is (TargetDestination:position - ship:position):mag.
  if  Distance > 50000 {
    //print "too far away, warping again".
    local TimeTillDesiredTrueAnomaly is T_TrueAnomaly["ETAToTrueAnomaly"](TargetDestination, 180).
    set TargetTime to time:seconds+TimeTillDesiredTrueAnomaly.
    warpto(TargetTime).
    wait until time:seconds > TargetTime.
  }
}

Function MainRelVelKill {
  Parameter TargetDestination.

  T_Steering["SteeringTargetRet"](TargetDestination).
  local DvNeeded is (ship:velocity:orbit-TargetDestination:velocity:orbit):mag.
  local CurDv is T_Other["CurrentDvCalc"]().
  local EndDv is CurDv - DvNeeded.
  D_ManExe["PerformBurn"](EndDv, 10, 100, true).
}

Function VeryFinalApproach {

  Parameter TargetDestination.

  local lock Distance to (TargetDestination:position - ship:position):mag.
  set warpmode to "rails".

  if Distance > 15000 {
    //print "extra boost needed".
    MainRelVelKill(TargetDestination).
    T_Steering["SteeringTarget"](TargetDestination).
    local DvNeeded is 100.
    local CurDv is T_Other["CurrentDvCalc"]().
    local EndDv is CurDv - DvNeeded.
    D_ManExe["PerformBurn"](EndDv, 10, 100, true).
    T_Steering["SteeringTargetRet"](TargetDestination).
    set warp to 2.
    wait until Distance < 10000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  if Distance > 3000 {
    //print "3000 meters".
    MainRelVelKill(TargetDestination).
    T_Steering["SteeringTarget"](TargetDestination).
    local DvNeeded is 40.
    local CurDv is T_Other["CurrentDvCalc"]().
    local EndDv is CurDv - DvNeeded.
    D_ManExe["PerformBurn"](EndDv, 10, 100, true).
    T_Steering["SteeringTargetRet"](TargetDestination).
    set warp to 1.
    wait until Distance < 1000.
    set warp to 0.
    MainRelVelKill(TargetDestination).
  }

  MainRelVelKill(TargetDestination).
  T_Steering["SteeringTarget"](TargetDestination).
  local DvNeeded is 10.
  local CurDv is T_Other["CurrentDvCalc"]().
  local EndDv is CurDv - DvNeeded.
  D_ManExe["PerformBurn"](EndDv, 10, 100, true).
  T_Steering["SteeringTargetRet"](TargetDestination).
  wait until Distance < 275.
  MainRelVelKill(TargetDestination).
}

Function CompleteRendezvous {
  Parameter TargetDestination.

  local Distance is (TargetDestination:position - ship:position):mag.
  if Distance > 7500 {
    MatchOrbit(TargetDestination).
    FinalApproach(TargetDestination, 5).
  }
  MainRelVelKill(TargetDestination).
  VeryFinalApproach(TargetDestination).
}

}

print "read lib_rendezvous".
