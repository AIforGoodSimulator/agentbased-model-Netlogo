breed [ walls wall ]
breed [ refugees refugee ]

globals [
  day ;ticks are minutes, this variable counts days
  hour ;ticks are minutes, this variable counts 24 hours format
  minute ;ticks are minutes, this converts to 60 minute format
  forwardstep ;movement step for people
  list-wash ;list of washing areas
  list-medical ;list of medical service areas
  list-food ;list of food distribution areas
  list-offices ;list of office and support areas
  list-houses ;list of houses, dormitories, and shelters
  list-greenzone ;list of places in the greenzone
  list-walls-horizontal ;list of boundary areas
  list-walls-vertical ;list of boundary areas
  PPEtransmission_probability ;transmission rate under PPE
  r0 ;reproduction rate
]

turtles-own [
  agegroup ;agegroup of person
  houselocation ;patch reference for house
  activitylocation ;location of their daily activity
  activitycounter ;how long person stays in daily activity
  activitylength ;how long the person should stay
  infectionlevel ;set the level of infection - 0 = not infected, 1 = infected, 2 = severe, 3 = recovered
  infectedtime ;how long person is infected
  infectionprobability ;a person's probability of having an infection
  hospitallocation ;closest hospital to go to
  recoveryprobability ;a person's probability of fully recovering after infection
  wakeup ;when a person wakes up
  fooddisttime ;when a person has lunch
  consultationtime ;when they go to the office to get support
  lockdownfood ;designated person to get food for housing unit during lockdown
  tested? ;if a person is tested or not
  vulnerable? ;if a person is vulnerable or not
]

patches-own [
  lockdownfoodhouse ;which time the household can get food during lockdown
]

to setup
  clear-all
  set forwardstep .9 ;play around with this number to make the movements more fluid
  createworld
  createpeople
  reset-ticks
end

to createworld
  ask patches [ set pcolor white ]

 ;washing areas - toilets, showers, water points
 set list-wash (patch-set patch 8 13 patch 8 14 patch 8 16 patch 12 17 patch 10 10 patch 10 8 patch 10 7 patch 14 9 patch 20 7 patch 19 8 patch 21 6)
 ask list-wash [
   set pcolor blue
   set plabel "W"
 ]

 ;medical service areas
 set list-medical (patch-set patch 16 8 patch 11 15 patch 21 8)
 ask list-medical [
   set pcolor red
   set plabel "+"
 ]

 ;food distribution area
 ifelse Shielding = true [
   set list-food (patch-set patch 18 10 patch 20 10)
   ask list-food [
     set pcolor orange
     set plabel "F"
   ]
 ]
 [
   set list-food patch 18 10
   ask list-food [
     set pcolor orange
     set plabel "F"
   ]
 ]

 ;office and support areas
 set list-offices (patch-set patch 12 15 patch 16 10 patch 22 8)
 ask list-offices [
   set pcolor grey
   set plabel "O"
 ]

 ;housing areas - housing units, shelters, temporary shelters
 set list-houses (patch-set
   patches with [pxcor >= 9 and pxcor <= 14 and pycor >= 13 and pycor <= 14]
   patches with [pxcor >= 9 and pxcor <= 14 and pycor = 11]
   patches with [pxcor >= 20 and pxcor <= 25 and pycor >= 11 and pycor <= 13]
   patches with [pxcor >= 23 and pxcor <= 26 and pycor >= 7 and pycor <= 9]
   patch 8 8
   patches with [pxcor >= 11 and pxcor <= 14 and pycor = 10]
   patches with [pxcor >= 16 and pxcor <= 18 and pycor >= 11 and pycor <= 12]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 6]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 7]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 8]
   patches with [pxcor < 7 and pxcor >= 2 and pycor = 9]
   patches with [pxcor < 7 and pxcor >= 3 and pycor = 10]
   patches with [pxcor < 7 and pxcor >= 3 and pycor = 11]
   patches with [pxcor < 7 and pxcor >= 2 and pycor = 12]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 13]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 14]
   patches with [pxcor < 7 and pxcor >= 2 and pycor = 15]
   patches with [pxcor < 7 and pxcor >= 3 and pycor = 16]
   patches with [pxcor < 7 and pxcor >= 2 and pycor = 17]
   patches with [pxcor < 7 and pxcor >= 1 and pycor = 18]
   patches with [pxcor > 15 and pxcor < 27 and pycor < 5]
   patches with [pxcor > 10 and pxcor < 27 and pycor > 18]
 )
 ask list-houses [
   set pcolor brown
   set plabel "H"
   if Lockdown = true [
     ifelse random-float 10 < 5 [set lockdownfoodhouse 1] [set lockdownfoodhouse 0]
   ]
 ]

 ;green zone houses for shielding
 set list-greenzone patches with [pxcor >= 20 and pxcor <= 26 and pycor >= 7 and pycor <= 14]
 ask list-greenzone [
   if Shielding = true [
     set pcolor green
   ]
 ]

 ;walls
  set list-walls-horizontal (patch-set patches with [pxcor > 7 and pxcor < 25 and pycor = 18] patch 8 7 patch 9 7 patches with [pxcor >= 10 and pxcor <= 14 and pycor = 6] patches with [pxcor > 14 and pxcor < 28 and pycor = 5])
  ask list-walls-horizontal [
    sprout-walls 1 [
      set shape "line"
      set color black
      set heading 90
    ]
  ]
  set list-walls-vertical (patch-set patches with [pxcor = 7 and pycor >= 8 and pycor <= 18] patches with [pxcor = 25 and pycor >= 16 and pycor <= 18] patches with [pxcor = 26 and pycor >= 12 and pycor <= 15] patches with [pxcor = 27 and pycor >= 6 and pycor < 15])
  ask list-walls-vertical [
    sprout-walls 1 [
      set shape "line"
      set color black
      set heading 0
    ]
  ]

  if Testing = true or Isolation = true [
    ask patch 0 0 [
      set pcolor black
      set plabel "Q"
    ]
  ]

end

to createpeople
  create-refugees population_size [
    set color black
    set size 0.5
    set shape "person"
    let rand random-float 100
    set agegroup (ifelse-value
      rand < percent_under18 ["under18"]
      rand >= percent_under18 and percent_under18 + percent_18-49 < 97 ["18-49"]
      ["50+"]
    )
    set houselocation min-one-of patches with [plabel = "H"] [count turtles-here] ;ensures that all households have people
    setxy [pxcor] of houselocation [pycor] of houselocation ;sends the person home at the start of the model
    set infectionprobability random-float 100 ;this is a person's probability of having an infection
    set recoveryprobability random-float 100 ;this is a person's probability of recovering after having an infection
    set wakeup 7 + random 3 ;wakes up between 7 and 10 to wash up
    set fooddisttime 12 + random 2 ;heads to lunch between 12 and 14
    set consultationtime 15 + random 3 ;goes to get support between 15 and 18
    set activitylocation houselocation
    set infectionlevel "0) susceptible"
    set hospitallocation min-one-of list-medical [distance [houselocation] of myself]
    set tested? false
    set vulnerable? (ifelse-value
      agegroup = "50+" and infectionprobability >= infection_prob_50+ [true]
      agegroup = "18-49" and infectionprobability >= infection_prob_18-49 [true]
      agegroup = "under18" and infectionprobability >= infection_prob_under18 [true]
      [false]
    )
  ]

  if outbreak = true [ ;if the outbreak switch is turned on, someone at random gets infected
    ask one-of refugees [
      set infectionlevel "1) exposed"
      set color 18
    ]
  ]



end


to go
  set minute ticks * 10 mod 60 ;ticks are 10 minutes this converts to a 60 minute intervals
  set hour floor (ticks * 10 / 60 mod 24) ;the ticks are 10 minutes, so this translates it into hours
  set day floor (ticks * 10 / 1440) + 1 ;the ticks are 10 minutes, so this translates it into days
  ask refugees [
    (ifelse
    Lockdown = true [lockdownactivity]
    Testing = true [testandisolateactivity]
    Isolation = true [isolatevulnerableactivity]
    Shielding = true [shieldingactivity]
    [refugeeactivity]
    )
  ]
  infectionprogress

  tick
end

to refugeeactivity
  if hour + minute / 100 = wakeup and infectionlevel != "2) infected" [ ;wake up between 7 and 11 to wash up
    set activitycounter 0
    set activitylocation min-one-of list-wash [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend washing up
  ]
  if infectionlevel != "2) infected" [activityandbackhome wakeup activitylocation activitylength]

  if hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" [ ;fooddisttime between 12 and 14
    set activitycounter 0
    set activitylocation list-food
    set activitylength 12 ;how many minutes to spend at lunch
  ]
  if infectionlevel != "2) infected" [activityandbackhome fooddisttime activitylocation activitylength]

  if hour + minute / 100 = consultationtime and infectionlevel != "2) infected" [ ;goes to get support between 15 and 18
    set activitycounter 0
    set activitylocation min-one-of list-offices [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend at support
  ]
  if infectionlevel != "2) infected" [activityandbackhome consultationtime activitylocation activitylength]

end

to lockdownactivity
  if hour + minute / 100 = 0 [
    set lockdownfood 0
    if count refugees-here with [lockdownfood = 1] < 1 and infectionlevel != "2) infected" [set lockdownfood 1]
  ]

  if hour + minute / 100 = wakeup and infectionlevel != "2) infected" [ ;wake up between 7 and 11 to wash up
    set activitycounter 0
    set activitylocation min-one-of list-wash [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend washing up
  ]
  if infectionlevel != "2) infected" [activityandbackhome wakeup activitylocation activitylength]

  if lockdownfood = 1 and hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 1 [ ;next activity is food distribution
    set activitycounter 0
    set activitylocation list-food
    set activitylength 12 ;how many minutes to spend at food distribution
  ]
  if lockdownfood = 1 and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 1 [activityandbackhome fooddisttime activitylocation activitylength] ;one person gets food for the housing unit during food dist hours

  if lockdownfood = 1 and hour + minute / 100 = consultationtime and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 0 [ ;next activity is food distribution
    set activitycounter 0
    set activitylocation list-food
    set activitylength 12 ;how many minutes to spend at food distribution
  ]
  if lockdownfood = 1 and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 0 [activityandbackhome consultationtime activitylocation activitylength] ;one person gets food for the housing unit during food dist hours
end

to testandisolateactivity
 if hour + minute / 100 = wakeup and (infectionlevel != "2) infected" and tested? = false) or (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [ ;wake up between 7 and 11 to wash up
    set activitycounter 0
    set activitylocation min-one-of list-wash [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend washing up
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [activityandbackhome wakeup activitylocation activitylength]

  if hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" and tested? = false [ ;food distribution time between 12 and 14
    set activitycounter 0
    set activitylocation list-food
    set activitylength 12 ;how many minutes to spend at food distribution
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [activityandbackhome fooddisttime activitylocation activitylength]

  if hour + minute / 100 = consultationtime and (infectionlevel != "2) infected" and tested? = false) [
    ifelse random-float 100 < %_tested_day [ ;random prob gets tested during consultation time
      set activitycounter 0
      set activitylocation hospitallocation
      set activitylength 6 ;how many minutes to spend at testing
    ]
    [
      set activitycounter 0
      set activitylocation min-one-of list-offices [distance [houselocation] of myself]
      set activitylength 6 ;how many minutes to spend at support
    ]
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [activityandbackhome consultationtime activitylocation activitylength]

  if infectionlevel = "1) exposed" and tested? = true [
    set activitylocation patch 0 0
    move activitylocation
  ]

  if hour + minute / 100 = consultationtime and (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [
    set activitycounter 0
    set activitylocation min-one-of list-offices [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend at support
  ]

  if (infectionlevel != "1) exposed" and infectionlevel != "2) infected" and tested? = true) [activityandbackhome consultationtime activitylocation activitylength]

end

to isolatevulnerableactivity
 if hour + minute / 100 = wakeup and (infectionlevel != "2) infected" and tested? = false) or (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [ ;wake up between 7 and 11 to wash up
    set activitycounter 0
    set activitylocation min-one-of list-wash [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend washing up
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [activityandbackhome wakeup activitylocation activitylength]

  if hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" and tested? = false [ ;food distribution time between 12 and 14
    set activitycounter 0
    set activitylocation list-food
    set activitylength 12 ;how many minutes to spend at food distribution
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [activityandbackhome fooddisttime activitylocation activitylength]

  if hour + minute / 100 = consultationtime and (infectionlevel != "2) infected" and tested? = false) [
    ifelse random-float 100 < %_tested_day [ ;random prob gets tested during consultation time
      set activitycounter 0
      set activitylocation hospitallocation
      set activitylength 6 ;how many minutes to spend at testing
    ]
    [
      set activitycounter 0
      set activitylocation min-one-of list-offices [distance [houselocation] of myself]
      set activitylength 6 ;how many minutes to spend at support
    ]
  ]
  if (infectionlevel != "2) infected" and tested? = false) or (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [activityandbackhome consultationtime activitylocation activitylength]

  if vulnerable? = true and tested? = true [
    set activitylocation patch 0 0
    move activitylocation
  ]

  if hour + minute / 100 = consultationtime and (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [
    set activitycounter 0
    set activitylocation min-one-of list-offices [distance [houselocation] of myself]
    set activitylength 6 ;how many minutes to spend at support
  ]

  if (vulnerable? = false and infectionlevel != "2) infected" and tested? = true) [activityandbackhome consultationtime activitylocation activitylength]

end

to shieldingactivity
  if ticks < 7 * 6 [
    if agegroup = "50+" and [pcolor] of houselocation != green [
      set houselocation min-one-of patches with [plabel = "H" and pcolor = green] [count refugees with [houselocation = myself]]
      set hospitallocation min-one-of list-medical with [pcolor = green] [distance [houselocation] of myself]
    ]
    if agegroup != "50+" and [pcolor] of houselocation = green [
      set houselocation min-one-of patches with [plabel = "H" and pcolor != green] [count refugees with [houselocation = myself]]
      set hospitallocation min-one-of list-medical with [pcolor != green] [distance [houselocation] of myself]
    ]
    if agegroup != "50+" and hospitallocation = patch 21 8 [
      set hospitallocation min-one-of list-medical with [pcolor != green] [distance [houselocation] of myself]
    ]
    if infectionlevel != "2) infected" and distance houselocation > 0 [
      move houselocation
    ]
  ]

  if [pcolor] of houselocation != green [
    if hour + minute / 100 = wakeup and infectionlevel != "2) infected" [ ;wake up between 7 and 11 to wash up
      set activitycounter 0
      set activitylocation min-one-of list-wash with [pcolor != green] [distance [houselocation] of myself]
      set activitylength 6 ;how many minutes to spend washing up
    ]
    if infectionlevel != "2) infected" [activityandbackhome wakeup activitylocation activitylength]

    if hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" [ ;fooddisttime between 12 and 14
      set activitycounter 0
      set activitylocation one-of list-food with [pcolor != green]
      set activitylength 12 ;how many minutes to spend at lunch
    ]
    if infectionlevel != "2) infected" [activityandbackhome fooddisttime activitylocation activitylength]

    if hour + minute / 100 = consultationtime and infectionlevel != "2) infected" [ ;goes to get support between 15 and 18
      set activitycounter 0
      set activitylocation min-one-of list-offices with [pcolor != green] [distance [houselocation] of myself]
      set activitylength 6 ;how many minutes to spend at support
    ]
    if infectionlevel != "2) infected" [activityandbackhome consultationtime activitylocation activitylength]
  ]

  if [pcolor] of houselocation = green [
    if hour + minute / 100 = 0 [
      set lockdownfood 0
      if count refugees-here with [lockdownfood = 1] < 1 and infectionlevel != "2) infected" [set lockdownfood 1]
    ]

    if hour + minute / 100 = wakeup and infectionlevel != "2) infected" [ ;wake up between 7 and 11 to wash up
      set activitycounter 0
      set activitylocation one-of list-wash with [pcolor = green]
      set activitylength 6 ;how many minutes to spend washing up
    ]
    if infectionlevel != "2) infected" [activityandbackhome wakeup activitylocation activitylength]

    if lockdownfood = 1 and hour + minute / 100 = fooddisttime and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 1 [ ;next activity is food distribution
      set activitycounter 0
      set activitylocation one-of list-food with [pcolor = green]
      set activitylength 12 ;how many minutes to spend at food distribution
    ]
    if lockdownfood = 1 and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 1 [activityandbackhome fooddisttime activitylocation activitylength] ;one person gets food for the housing unit during food dist hours

    if lockdownfood = 1 and hour + minute / 100 = consultationtime and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 0 [ ;next activity is food distribution
      set activitycounter 0
      set activitylocation one-of list-food with [pcolor = green]
      set activitylength 12 ;how many minutes to spend at food distribution
    ]
    if lockdownfood = 1 and infectionlevel != "2) infected" and [lockdownfoodhouse] of houselocation = 0 [activityandbackhome consultationtime activitylocation activitylength] ;one person gets food for the housing unit during food dist hours
  ]
end

to activityandbackhome [time location lenghttime]
  if hour >= time [
    if activitycounter < lenghttime [
      move location
    ]
    if patch-here = location and activitycounter < lenghttime [
      if (Testing = true and infectionlevel = "1) exposed" and [plabel] of patch-here = "+") or (Isolation = true and vulnerable? = true and [plabel] of patch-here = "+") [ set tested? true ]
      set activitycounter activitycounter + 1
      infect
    ]
    if activitycounter = lenghttime [
      move houselocation
    ]
  ]
end


to move [location] ;this moves people towards the place they want to go based on the steps per minute set at the start
  face location
  ifelse distance location <= forwardstep
    [ move-to location ]
    [ fd forwardstep ]
end

to infect
  if (infectionlevel = "0) susceptible") and (any? turtles-here with [infectionlevel = "1) exposed" or infectionlevel = "2) infected"]) [
      if ticks mod 6 = 0 and random-float 100 < (ifelse-value PPE = true [(100 - reduction_transmission) * transmission_probability / 100] [transmission_probability]) [
        set infectionlevel "1) exposed"
      ]
  ]
end


to infectionprogress
  ask refugees [
    if hour + minute / 100 < wakeup [
      infect
    ]

    if infectionlevel = "1) exposed" or infectionlevel = "2) infected" [ ;if someone is infected, this counter shows for how long they have been infected
      set infectedtime infectedtime + 1
    ]

    if infectedtime >= incubation_time * 144 [ ;if someone is infected for more than the severity period, their condition becomes severe with a certain probability
      set infectionlevel (ifelse-value
        agegroup = "50+" and infectionprobability <= infection_prob_50+ [ "2) infected" ]
        agegroup = "18-49" and infectionprobability <= infection_prob_18-49 [ "2) infected" ]
        agegroup = "under18" and infectionprobability <= infection_prob_under18 [ "2) infected" ]
        [infectionlevel])
    ]

    if infectedtime >= (incubation_time) * 144 and infectionlevel != "2) infected" [ ;if someone is not severe past the incubation time, their condition recovers
      set infectionlevel "3) recovered"
      set vulnerable? false
    ]

    if infectedtime >= (incubation_time + infection_time) * 144 and infectionlevel = "2) infected" and recoveryprobability < infection_probability_recovery[
      set infectionlevel "3) recovered"
      set vulnerable? false
    ]

    set color(ifelse-value ;this colors people by infection level
      infectionlevel = "1) exposed" [18]
      infectionlevel = "2) infected" [15]
      infectionlevel = "3) recovered" [65]
      [black])

    if infectionlevel = "2) infected" [
      move hospitallocation
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
35
56
623
485
-1
-1
20.0
1
10
1
1
1
0
0
0
1
0
28
0
20
1
1
0
ticks
30.0

BUTTON
672
197
761
230
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
672
235
761
268
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
30
10
642
47
VIRUS SPREAD IN MORIA REFUGEE CAMP
20
0.0
1

MONITOR
666
17
716
62
Day
day
17
1
11

MONITOR
716
17
766
62
Hour
hour
17
1
11

TEXTBOX
663
293
813
311
Demographic inputs:
12
0.0
1

TEXTBOX
902
294
1052
312
Health inputs:
12
0.0
1

SWITCH
661
146
771
179
Outbreak
Outbreak
0
1
-1000

PLOT
784
24
1304
267
Infection Level of Population
NIL
NIL
0.0
3500.0
0.0
500.0
true
true
"" ""
PENS
"Exposed" 1.0 0 -1069655 true "" "plot count refugees with [infectionlevel = \"1) exposed\"]"
"Infected" 1.0 0 -2674135 true "" "plot count refugees with [infectionlevel = \"2) infected\"]"
"Recovered" 1.0 0 -13840069 true "" "plot count refugees with [infectionlevel = \"3) recovered\"]"

SLIDER
899
356
1151
389
incubation_time
incubation_time
0
14
5.0
1
1
days
HORIZONTAL

SLIDER
900
315
1151
348
transmission_probability
transmission_probability
0
100
15.0
5
1
%
HORIZONTAL

SLIDER
662
444
865
477
percent_under18
percent_under18
0
100
62.0
1
1
%
HORIZONTAL

SLIDER
662
400
864
433
percent_18-49
percent_18-49
0
100
35.0
1
1
%
HORIZONTAL

SLIDER
662
357
865
390
percent_50+
percent_50+
0
100
3.0
1
1
%
HORIZONTAL

SLIDER
900
399
1153
432
infection_prob_50+
infection_prob_50+
0
100
60.0
5
1
%
HORIZONTAL

SLIDER
900
440
1154
473
infection_prob_18-49
infection_prob_18-49
0
100
45.0
5
1
%
HORIZONTAL

SLIDER
901
482
1156
515
infection_prob_under18
infection_prob_under18
0
100
25.0
5
1
%
HORIZONTAL

SLIDER
902
524
1156
557
infection_time
infection_time
0
14
5.0
1
1
days
HORIZONTAL

SLIDER
902
564
1156
597
infection_probability_recovery
infection_probability_recovery
0
100
50.0
1
1
%
HORIZONTAL

TEXTBOX
43
502
193
520
Interventions:
12
0.0
1

SWITCH
40
527
198
560
PPE
PPE
1
1
-1000

SLIDER
38
570
198
603
reduction_transmission
reduction_transmission
0
100
20.0
1
1
%
HORIZONTAL

SWITCH
216
527
332
560
Lockdown
Lockdown
1
1
-1000

SWITCH
348
527
455
560
Testing
Testing
1
1
-1000

SLIDER
337
571
588
604
%_tested_day
%_tested_day
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
662
317
866
350
population_size
population_size
0
1000
500.0
100
1
people
HORIZONTAL

SWITCH
470
527
573
560
Isolation
Isolation
1
1
-1000

SWITCH
595
526
699
559
Shielding
Shielding
0
1
-1000

@#$#@#$#@
Basic daily routine of refugees:
- wake up between 7am and 10am
- go to nearest wash facility (W in blue) to shower, go to the toilet, etc.
- return home
- go to food distribution center (F in orange) to get food between 12pm and 2pm
- return home
- go to nearest office (O in grey) to get support and consultation between 3pm and 6pm
- return home


Exposure to COVID-19:
- one refugee at random is exposed to the virus
- virus spreads only when people are in the same building with a certain transmission probability set by the slider - they then get exposed and turn pink
- after the incubation time - set by the slider - they either recover or they get infected and show serious symptions - infection rate is based on their age group and the sliders in the model
- if refugees are infected with the virus and experience serious symptoms, they turn red and are sent to one of the medical service areas ("+" in red)
- refugees infected with the virus recover after the infection period and with a probability of recovery - both set by the sliders
- if refugees recover, they turn green and resume their daily routine


Intervention assumptions:

PPE:
- everyone gets PPE
- PPE reduces transmission by percentage set in the slider in the model

Lockdown:
- refugees allowed to wake up and use wash facilities
- between 12pm and 2pm only one refugee is allowed to go get food for the housing unit for 50% of the housing units
- between 3pm and 6pm only one refugee is allowed to get food for the housing unit for the remaining 50% of the housing units
- offices are closed and no consultation hours are allowed

Testing of Infected:
- refugees go about their normal daily routine
- during the consultation time between 3pm and 6pm a certain percentage of refugees - set by the slider - go to the medical center instead to get tested
- if tested positive for COVID-19 (if they are exposed) then they get sent to an isolation area set up outside the camp
- refugees who are not tested still go about their daily routine
- refugees who are infected get sent to the hospital regardless of if they are isolated or not
- refugees who were isolated and recover come back to the camp to resume their normal activities

Isolation of Vulnerable:
- refugees go about their normal daily routine
- during the consultation time between 3pm and 6pm a certain percentage of refugees - set by the slider - go to the medical center instead to get checked
- if they are assumed to be vulnerable to the infection then they are quarantined
- refugees who are not tested still go about their daily routine
- refugees who are infected get sent to the hospital regardless of if they are isolated or not
- refugees who were isolated and recover come back to the camp to resume their normal activities

Shielding:
- a greenzone is set-up in one area of the camp containing one wash facility, one hospital, and one office
- in addition, a food distribution center is set-up in the greenzone
- at the start, refugees 50+ are placed into this greenzone, while refugees under 50 are removed from this greenzone
- refugees in the greenzone follow the Lockdown daily routine
- refugees outside the greenzone follow their normal basic daily routine
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="BaseCase" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="PPE_25percentreduction" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="PPE_50percentreduction" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="PPE_75percentreduction" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Lockdown" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Isolation_25percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Isolation_50percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Isolation_75percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Testing_25percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Testing_50percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Testing_75percent_tested" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count refugees with [infectionlevel = "1) exposed"]</metric>
    <metric>count refugees with [infectionlevel = "2) infected"]</metric>
    <metric>count refugees with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="infection_probability_recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transmission_probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="incubation_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_tested_day">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_under18">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Testing">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Isolation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_18-49">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population_size">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_50+">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PPE">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infection_prob_50+">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_18-49">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
